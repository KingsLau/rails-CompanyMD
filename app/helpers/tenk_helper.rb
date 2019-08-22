module TenkHelper
require 'rest-client'
require 'nokogiri'
require 'open-uri'

def set_10k(ticker)
  tenk = []
  url = 'https://api.sec-api.io'
  body = { "query": {
            "query_string": { "query": "ticker: #{ticker} AND formType:\"10-K\"" } },
            "from": "0",
            "size": "10",
            "sort": [{ "filedAt": { "order": "desc" } }] }

  json_body = body.to_json

  res = RestClient.post url, json_body, {content_type: :json, accept: :json}
  data = JSON.parse(res.body)
  data["filings"].each do |package|
    tenk << { link: package["linkToHtml"], date: package["filedAt"] }
    end
  scrape_to_file(tenk)
  end

  private

  def scrape_to_file(links)
    links.map do |link|
      new_link = "https://www.sec.gov"
      doc = Nokogiri::HTML(open(link[:link]).read)
      items = doc.css('#contentDiv')
      subitem = items.css('div[id="contentDiv"] div[id="formDiv"] a')
      if subitem.css('a[href*="10k.h"]').length > 0
        new_link += subitem[0].attributes['href'].value
      elsif subitem.css('a[href*="10-k.h"]').length > 0
        new_link += subitem[0].attributes['href'].value
      end
      link[:link] = new_link
    end
    clean_up(links)
  end

  def clean_up(to_clean)
    cleaned = []
    to_clean.each do |link_set|
      if link_set[:link].length > 20
        cleaned << link_set
      end
    end
    cleaned
  end

end