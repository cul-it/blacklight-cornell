
Then("the availability icon should show a checkmark") do
    within('div.availability.card') do
        expect(find('div.status')).to have_selector('i.fa-check')
    end
end

Then("the availability icon should show a clock") do
    within('div.availability.card') do
        expect(find('div.status')).to have_selector('i.fa-clock-o')
    end
end

Then("availability should show status {string}") do |string|
    within('div.availability.card') do
        expect(find('div.status')).to have_content(string)
    end
end

Then("availability should show the returned date") do
    within('div.availability.card') do
        expect(find('div.status').text).to match(/Returned \d{2}\/\d{2}\/\d{2}/)
    end
end

Then("availability should show the due date") do
    within('div.availability.card') do
        expect(find('div.status').text).to match(/due \d{2}\/\d{2}\/\d{2}/)
    end
end

Then("the first availability icon for {string} should show a clock") do |string|
    holding = find(:xpath, "//div[contains(@class, 'holding')]/div[contains(@class, 'location') and contains(text(),'#{string}')]/parent::*")
    within(holding) do
        expect(first('div.status')).to have_selector('i.fa-clock-o')
    end
end

Then("the first availability icon for {string} should show a checkmark") do |string|
    holding = find(:xpath, "//div[contains(@class, 'holding')]/div[contains(@class, 'location') and contains(text(),'#{string}')]/parent::*")
    within(holding) do
        expect(first('div.status')).to have_selector('i.fa-check')
    end
end

Then("the first availability for {string} should show status {string}") do |string, string2|
    holding = find(:xpath, "//div[contains(@class, 'holding')]/div[contains(@class, 'location') and contains(text(),'#{string}')]/parent::*")
    within(holding) do
        expect(first('div.status')).to have_content(string2)
    end
end

Then("the first availability for {string} should show the due date and time") do |string|
    holding = find(:xpath, "//div[contains(@class, 'holding')]/div[contains(@class, 'location') and contains(text(),'#{string}')]/parent::*")
    within(holding) do
        expect(first('div.status').text).to match(/due \d{2}\/\d{2}\/\d{2} \d{1,2}\:\d{2} [ap]m/)
    end
end

Then("the first availability for {string} should show the date") do |string|
    holding = find(:xpath, "//div[contains(@class, 'holding')]/div[contains(@class, 'location') and contains(text(),'#{string}')]/parent::*")
    within(holding) do
        expect(first('div.status').text).to match(/\d{2}\/\d{2}\/\d{2}/)
    end
end

Then("the availibility for {string} should show a message {string}") do |string, string2|
    holding = find(:xpath, "//div[contains(@class, 'holding')]/div[contains(@class, 'location') and contains(text(),'#{string}')]/parent::*")
    within(holding) do
        expect(find(:xpath, "//div[contains(@class, 'message') and contains(text(),'#{string2}')]")).to have_content(string2)
    end
end

Then("the availibility for {string} should show a status {string}") do |string, string2|
    holding = find(:xpath, "//div[contains(@class, 'holding')]/div[contains(@class, 'location') and contains(text(),'#{string}')]/parent::*")
    within(holding) do
        expect('div.status').to have_content(string2)
    end
end