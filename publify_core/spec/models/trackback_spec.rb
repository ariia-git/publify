# frozen_string_literal: true

require "rails_helper"
require "publify_core/testing_support/dns_mock"

describe Trackback, "With the various trackback filters loaded and DNS mocked out appropriately", type: :model do
  let(:article) { create(:article) }

  before do
    @blog = create(:blog)
    @blog.sp_global = true
    @blog.default_moderate_comments = false
    @blog.save!
  end

  it "Incomplete trackbacks should not be accepted" do
    tb = Trackback.new(blog_name: "Blog name",
                       title: "Title",
                       excerpt: "Excerpt",
                       article_id: create(:article).id)
    expect(tb).not_to be_valid
    expect(tb.errors["url"]).to be_any
  end

  it "A valid trackback should be accepted" do
    tb = Trackback.new(blog_name: "Blog name",
                       title: "Title",
                       url: "http://foo.com",
                       excerpt: "Excerpt",
                       article_id: create(:article).id)
    expect(tb).to be_valid
    tb.save
    expect(tb.guid.size).to be > 15
    expect(tb).not_to be_spam
  end

  it "Trackbacks with a spammy link in the excerpt should be rejected" do
    tb = article.trackbacks.build(ham_params.merge(excerpt: '<a href="http://chinaaircatering.com">spam</a>'))
    tb.classify_content
    expect(tb).to be_spammy
  end

  it "Trackbacks with a spammy source url should be rejected" do
    tb = article.trackbacks.build(ham_params.merge(url: "http://www.chinaircatering.com"))
    tb.classify_content
    expect(tb).to be_spammy
  end

  it "Trackbacks from a spammy ip address should be rejected" do
    tb = article.trackbacks.build(ham_params.merge(ip: "212.42.230.207"))
    tb.classify_content
    expect(tb).to be_spammy
  end

  def ham_params
    { blog_name: "Blog", title: "trackback", excerpt: "bland",
      url: "http://notaspammer.com", ip: "212.42.230.206" }
  end
end
