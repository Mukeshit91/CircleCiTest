require 'spreadsheet'
require 'pry'

Spreadsheet.client_encoding = 'UTF-8'
book = Spreadsheet.open File.expand_path(EXCEL_WORKBOOK, __FILE__)

Given(/^user logins and navigates to home page$/) do
  visit '/'
  # page.driver.browser.manage.window.maximize
  # Capybara.current_session.driver.browser.manage.window.maximize
  # Capybara.current_session.driver.browser.manage.window.resize_to(1280, 1024)
  page.fill_in 'Email or Phone', :with => LOGIN_USER
  page.fill_in 'Password', :with => LOGIN_PASSWORD
  page.click_button 'Log In'
  page.click_link 'Home'
end

def lookup_select_value(value)
  page.find("img[alt='Lease Lookup (New Window)']").click
  sleep 10
  page.driver.switch_to_window(page.driver.window_handles.last)
  page.driver.browser.switch_to.frame('resultsFrame')
  click_on value
  page.driver.switch_to_window(page.driver.window_handles.first)
end

def form_fill(value, element)
  Capybara.ignore_hidden_elements = false
  # element = page.find_by_id(element_id)
  # binding.pry
  p element.class
  if element[:class] == 'select'
    element.select value
  elsif element.tag_name == 'input' && element.class == 'dateInput' && element[:type] == 'text'
    element.set value
  elsif element.tag_name == 'input' && element[:class] == 'readonly' && element[:type] == 'text'
    lookup_select_value(value)
  elsif element[:type] == 'checkbox'
    element.click
  elsif element.tag_name == 'textarea' || element.tag_name == 'input'
    element.set value
  end
  Capybara.ignore_hidden_elements = true
end

When(/^user fill\-in "([^"]*)" information from regression/) do |screen|
  # label_list = page.all(:xpath, '//label/span')
  # # p label_list
  element = Hash.new
  # label_list.each do |label|
  #   # p label
  #   label_text = label.text.sub('* ', '')
  #   element[label_text] = label_text
  #   p label_text
  # end
  # binding.pry
  #   sleep(10)
  work_sheet = book.worksheet EXCEL_WORKSHEET
  colindex = work_sheet.row(0).index(screen)
  work_sheet.drop(1).each do |row|
    field_name = row[colindex]
    field_value = row[colindex+1]
    break if field_name == nil
    # sleep(4)
    label = page.find(:xpath, '//span[text()="'+field_name+'"][not(contains(@class, "slds-truncate"))]')
    if label[:id].include? "a-label"
      element = page.find(:xpath, '//span[text()="'+field_name+'"]/../../div//a')
      # binding.pry
      element.click
      sleep 2
      element1 = page.find(:xpath, '//a[contains(@title,"'+field_value+'")]')
      element1.click
    elsif page.find(:xpath, '//label/span[text()="'+field_name+'"]/../..')[:class].include? "checkbox"
      page.find(:xpath, '//label/span[text()="'+field_name+'"]/../../input').click
    elsif page.find(:xpath, '//label/span[text()="'+field_name+'"]/../..')[:class].include? "textarea"
      page.find(:xpath, '//label/span[text()="'+field_name+'"]/../..//textarea').set field_value
    elsif page.find(:xpath, '//label/span[text()="'+field_name+'"]/../..')[:class].include? "Lookup"
      page.find(:xpath, '//label/span[text()="'+field_name+'"]/../..//input').set field_value
      page.find(:xpath, '//label/span[text()="'+field_name+'"]/../..//input').send_keys :enter
      click_link(field_value)
    else
      element = page.find(:xpath, '//label/span[text()="'+field_name+'"]/../..//input')
      element.set field_value
    end
    # if label_id.include? "a-label"
    # end
    #   element = page.find(:xpath, '//label/span[text()="'+field_name+'"]/../..//input')
    #   element1 = page.find(:xpath, '//span[text()="Aircraft Type"]/../../div//a')
    #   element1.click
    # sleep(3)
    # element2 = page.find(:xpath, '//a[contains(@title,"A319")]')
    # element2.click
    # binding.pry
    # field_value = "A340"
    # p element.tag_name
    # binding.pry
    if field_value != nil && field_name != nil  #&& element[field_name] != nil
      # binding.pry
      # form_fill(field_value, element)
      # binding.pry
    elsif element[field_name] == nil
      "Element : " + field_name + " not in application"
    end
  end
end

And(/^user clicks on "([^"]*)" button$/) do |btn_name|
  click_button(btn_name)
  sleep 2
end

# And(/^user clicks on "([^"]*)" link/) do |btn_name|
#   sleep 10
#   click_link(btn_name, :match => :first)
#   sleep 2
# end

def get_date(value)
  date = Time.now
  if value.include? 'YEAR_MONTH'
    date = date.localtime("+05:30").strftime('%Y-%m')
    value.slice! 'YEAR_MONTH'
    value = value + date
  elsif value.include? 'TODAYS_DATE'
    date = Time.now
    date = date.localtime("+05:30").strftime('%-m/%-d/%Y')
    value.slice! 'TODAYS_DATE'
    value = value + date
  end
  value
end

Then(/^verify that newly added record is displayed under section "([^"]*)"$/) do |section_title, table|
  section = page.find('h3', :text => section_title, :match => :first)
  section_id = section[:id]
  section_id = section_id.sub('title', 'body')
  section_table = page.find_by_id(section_id)
  datarow = section_table.all('tr.dataRow')
  header = page.all('table.list tr.headerRow th').map(&:text)
  # datarow = page.all('table.list tr.dataRow')
  table.hashes.zip(datarow).each do |row, data|
    row.each do |key, value|
      expect(header).to include(key)
      value = get_date(value)
      expect(data.text).to include(value)
    end
  end
  # binding.pry
end

When(/^user navigates to "([^"]*)" tab$/) do |tab_name|
  if has_link?(tab_name, :match => :first)
    click_link(tab_name, :match => :first)
  else
    # page.find_by_id('MoreTabs_Tab').click
    show_more = page.find(:xpath,'//span[text()="More"]')
    show_more.click
    click_link(tab_name, :match => :first)
  end
end

And(/^accept browser pop\-up$/) do
  page.driver.browser.switch_to.alert.accept
end

And(/^user selects newly added "([^"]*)"/) do |aircraft_name|
  click_link(aircraft_name, :exact => true, :match => :first)
end

Then(/^Verify that aircraft "([^"]*)" is deleted$/) do |aircraft_name|
  datarow = page.all('table.list tr.first .dataCell').map(&:text)
  expect(datarow).not_to include(aircraft_name)
end

And(/^user fill\-in aircraft "([^"]*)" section$/) do |arg, table|
  # table is a table.hashes.keys # => [:Line #, :Number Of Landing Gears]
  table.hashes.each do |row|
    row.each do |key, value|
      # label = page.find('label', :text => key, :match => :first)
      # element_id = label[:for]
      # form_fill(value, element_id)
      if page.find(:xpath, '//label/span[text()="'+key+'"]/../..')[:class].include? "Lookup"
        page.find(:xpath, '//label/span[text()="'+key+'"]/../..//input').set value
        page.find(:xpath, '//label/span[text()="'+key+'"]/../..//input').send_keys :enter
        page.find(:xpath, '//a[text()="'+value+'"and contains(@class, "forceOutputLookup")]').click
      else
        element = page.find(:xpath, '//label/span[text()="'+key+'"]/../..//input')
        element.set value
      end
    end
  end
end

Then(/^verify that Aircraft status is changed to assigned$/) do |table|
  step 'verify that newly added record is displayed in the page', table
end

Then(/^verify that Assembly Utilizations are auto created$/) do |table|
  step 'verify that newly added record is displayed in the page', table
end

Then(/^verify that following values are populated in "([^"]*)" section$/) do |section_name, table|
  section = page.find('.pbSubheader', text: section_name)
  td_list = page.find(:xpath, "//div[preceding-sibling::div[@id='"+ section[:id]+ "']]", :match => :first).all('td')
  fields = Hash.new
  (0...td_list.length).step(2) do |i|
    fields[td_list[i].text] = td_list[i+1].text
  end
  table.hashes.each do |row|
    row.each do |key, value|
      expect(fields[key]).to include(value)
    end
  end
end

And(/^user selects assembly utilization "([^"]*)"$/) do |item_type|
  element = page.find('td.dataCell', :text => item_type, :match => :first)
  page.click_link element.find(:xpath, '../th').text
end

Then(/^verify following error message is displayed "([^"]*)"$/) do |error_msg|
  expect(page.find('.pbError').text).to include(error_msg)
end

And(/^verify the pop\-up text "([^"]*)"$/) do |msg_text|
  actual = page.driver.browser.switch_to.alert.text
  expect(actual).to include(msg_text)
end

Then(/^verify following field level error message is displayed "([^"]*)"$/) do |error_msg|
  expect(page.find('.errorMsg').text).to include(error_msg)
end

Then(/^verify following message is displayed "([^"]*)"$/) do |msg|
  expect(page.find('.messageText').text).to include(msg)
end

Then(/^verify that newly added record is displayed in the page$/) do |table|
  sleep 5
  headers = page.all(:xpath, '//th/div/a/span[2]').map(&:text)
  datarow = page.all(:xpath, '//div/div/table/tbody/tr[1]//span[@class="slds-grid slds-grid--align-spread forceInlineEditCell"]').map(&:text)
  expect(table.raw[0]).to match_array(headers)
  expect(table.raw[1]).to match_array(datarow)
  # table.hashes.zip(datarow).each do |row, data|
  #   row.each do |key, value|
  #     # expect(headers).to include(key)
  #     expect(data).to include(value)
  #   end
  # end
end

And(/^user clicks on "([^"]*)" link$/) do |link_text|
  if has_link?(link_text, :match => :first)
    click_link(link_text, :exact => true, :match => :first)
  end
end

And(/^user select "([^"]*)" for "([^"]*)"$/) do |value, label|
  label_element = page.find('label', :text => label, :match => :first)
  form_fill(value, label_element[:for])
end

Then(/^verify that following values are populated in "([^"]*)" header section$/) do |section_header_name, table|
  td_list = page.find('.pbSubsection', :match => :first).all('td')
  fields = Hash.new
  (0...td_list.length).step(2) do |i|
    fields[td_list[i].text] = td_list[i+1].text
  end
  table.hashes.each do |row|
    row.each do |key, value|
      expect(fields[key]).to include(value)
    end
  end
end

And(/^user clicks on "([^"]*)" text$/) do |arg|
  assembly = page.find(:xpath, '//span[text()="'+arg+'"]')
  assembly.click
end


And(/^user click select "([^"]*)" option$/) do |arg|
  option_element = page.find(:xpath, '//option[text()="'+arg+'"]')
  option_element.click
end

Then(/^verify that newly added record is displayed in the "([^"]*)" section$/) do |section, table|
  sleep 5
  headers = page.all(:xpath, '//div[contains(@class,"windowViewMode-normal")]//span[text()="'+section+'"]/ancestor::article//th[contains(@class,"initialSortAsc")]').map(&:text)
  datarow = page.all(:xpath, '//div[contains(@class,"windowViewMode-normal")]//span[text()="'+section+'"]/ancestor::article//tbody//th').map(&:text)
  expecteddata = table.raw[1].reject { |c| c.empty? }
  datarow.push(*page.all(:xpath, '//div[contains(@class,"windowViewMode-normal")]//span[text()="'+section+'"]/ancestor::article//tbody//td/span').map(&:text))
  expect(headers).to match_array(table.raw[0])
  expect(datarow).to match_array(expecteddata)
end