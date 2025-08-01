require "test_helper"

class UserSearchTest < ActiveSupport::TestCase
  def setup
    @ip_address = "192.168.1.1"
    @query = "test search"
  end

  test "should be valid with valid attributes" do
    user_search = UserSearch.new(
      ip_address: @ip_address,
      query: @query
    )
    assert user_search.valid?
  end

  test "should require ip_address" do
    user_search = UserSearch.new(query: @query)
    assert_not user_search.valid?
    assert_includes user_search.errors[:ip_address], "can't be blank"
  end

  test "should require query" do
    user_search = UserSearch.new(ip_address: @ip_address)
    assert_not user_search.valid?
    assert_includes user_search.errors[:query], "can't be blank"
  end

  test "clean_pyramid_queries_for should remove redundant queries" do
    # Create searches with pyramid pattern
    UserSearch.create!(
      ip_address: @ip_address,
      query: "ruby",
      created_at: 1.minute.ago
    )
    UserSearch.create!(
      ip_address: @ip_address,
      query: "ruby on",
      created_at: 30.seconds.ago
    )
    UserSearch.create!(
      ip_address: @ip_address,
      query: "ruby on rails",
      created_at: 10.seconds.ago
    )

    initial_count = UserSearch.where(ip_address: @ip_address).count
    assert_equal 3, initial_count

    UserSearch.clean_pyramid_queries_for(@ip_address)

    remaining_searches = UserSearch.where(ip_address: @ip_address)
    assert_equal 1, remaining_searches.count
    assert_equal "ruby on rails", remaining_searches.first.query
  end

  test "clean_pyramid_queries_for should not affect searches from different IPs" do
    other_ip = "192.168.1.2"
    
    UserSearch.create!(
      ip_address: @ip_address,
      query: "test",
      created_at: 1.minute.ago
    )
    UserSearch.create!(
      ip_address: other_ip,
      query: "test query",
      created_at: 30.seconds.ago
    )

    UserSearch.clean_pyramid_queries_for(@ip_address)

    assert_equal 1, UserSearch.where(ip_address: @ip_address).count
    assert_equal 1, UserSearch.where(ip_address: other_ip).count
  end

  test "clean_pyramid_queries_for should only affect recent searches" do
    # Old search (outside 2 minutes window)
    old_search = UserSearch.create!(
      ip_address: @ip_address,
      query: "old",
      created_at: 3.minutes.ago
    )
    
    # Recent searches
    UserSearch.create!(
      ip_address: @ip_address,
      query: "new",
      created_at: 1.minute.ago
    )
    UserSearch.create!(
      ip_address: @ip_address,
      query: "new search",
      created_at: 30.seconds.ago
    )

    UserSearch.clean_pyramid_queries_for(@ip_address)

    remaining_searches = UserSearch.where(ip_address: @ip_address)
    assert_equal 2, remaining_searches.count
    assert_includes remaining_searches.pluck(:query), "old"
    assert_includes remaining_searches.pluck(:query), "new search"
  end

  test "remove_duplicates_for should remove duplicate queries" do
    # Create duplicate searches
    UserSearch.create!(
      ip_address: @ip_address,
      query: "duplicate query",
      created_at: 2.minutes.ago
    )
    UserSearch.create!(
      ip_address: @ip_address,
      query: "DUPLICATE QUERY",
      created_at: 1.minute.ago
    )
    UserSearch.create!(
      ip_address: @ip_address,
      query: " duplicate query ",
      created_at: 30.seconds.ago
    )

    initial_count = UserSearch.where(ip_address: @ip_address).count
    assert_equal 3, initial_count

    UserSearch.remove_duplicates_for(@ip_address)

    remaining_searches = UserSearch.where(ip_address: @ip_address)
    assert_equal 1, remaining_searches.count
    # Should keep the most recent one
    assert remaining_searches.first.created_at >= 30.seconds.ago
  end

  test "remove_duplicates_for should not affect searches from different IPs" do
    other_ip = "192.168.1.2"
    
    UserSearch.create!(
      ip_address: @ip_address,
      query: "same query",
      created_at: 1.minute.ago
    )
    UserSearch.create!(
      ip_address: other_ip,
      query: "same query",
      created_at: 30.seconds.ago
    )

    UserSearch.remove_duplicates_for(@ip_address)

    assert_equal 1, UserSearch.where(ip_address: @ip_address).count
    assert_equal 1, UserSearch.where(ip_address: other_ip).count
  end

  test "remove_duplicates_for should keep most recent duplicate" do
    first_search = UserSearch.create!(
      ip_address: @ip_address,
      query: "test",
      created_at: 2.minutes.ago
    )
    second_search = UserSearch.create!(
      ip_address: @ip_address,
      query: "test",
      created_at: 1.minute.ago
    )

    UserSearch.remove_duplicates_for(@ip_address)

    remaining_searches = UserSearch.where(ip_address: @ip_address)
    assert_equal 1, remaining_searches.count
    assert_equal second_search.id, remaining_searches.first.id
  end
end
