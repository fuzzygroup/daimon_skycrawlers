require "helper"
require "daimon_skycrawlers/sitemap_parser"

class SitemapParserTest < Test::Unit::TestCase
  setup do
    Typhoeus::Expectation.clear
  end

  data("given urls are not found" => 404,
       "server error" => 500)
  test "given urls are not found" do |(status)|
    url = "http://example.com/sitemap.xml"
    response = Typhoeus::Response.new(code: status, effective_url: url)
    Typhoeus.stub(url).and_return(response)
    sitemap_parser = DaimonSkycrawlers::SitemapParser.new([url])
    message = "HTTP requset to #{url} failed. status: #{status}"
    assert_raise(DaimonSkycrawlers::SitemapParser::Error.new(message)) do
      sitemap_parser.parse
    end
  end

  test "empty sitemap" do
    url = "http://example.com/sitemap.xml"
    response = Typhoeus::Response.new(code: 200, effective_url: url, headers: {}, body: "")
    Typhoeus.stub(url).and_return(response)
    sitemap_parser = DaimonSkycrawlers::SitemapParser.new([url])
    message = "Malformed sitemap.xml no <sitemapindex> or <urlset>"
    assert_raise(DaimonSkycrawlers::SitemapParser::Error.new(message)) do
      sitemap_parser.parse
    end
  end

  test "plain sitemap" do
    url = "http://example.com/sitemap.xml"
    response = Typhoeus::Response.new(code: 200,
                                      effective_url: url,
                                      headers: {},
                                      body: fixture_path("sitemap/sitemap.xml").read)
    Typhoeus.stub(url).and_return(response)
    sitemap_parser = DaimonSkycrawlers::SitemapParser.new([url])
    expected = [
      "https://example.com/1",
      "https://example.com/2",
    ]
    assert_equal(expected, sitemap_parser.parse)
  end
end
