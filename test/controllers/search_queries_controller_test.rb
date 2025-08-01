require "test_helper"

class SearchQueriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @ip_address = "192.168.1.1"
    # Create test data for analytics
    create_test_searches
  end

  def teardown
    UserSearch.destroy_all
  end

  test "should create user search" do
    assert_difference('UserSearch.count') do
      post search_queries_path,
           params: { query: "test search" },
           headers: { 'REMOTE_ADDR' => @ip_address }
    end
  end

  test "should clean pyramid queries after creation" do
    # Create pyramid pattern
    post search_queries_path,
         params: { query: "ruby" },
         headers: { 'REMOTE_ADDR' => @ip_address }
    
    post search_queries_path,
         params: { query: "ruby on" },
         headers: { 'REMOTE_ADDR' => @ip_address }
    
    post search_queries_path,
         params: { query: "ruby on rails" },
         headers: { 'REMOTE_ADDR' => @ip_address }

    # Should only keep the most complete query
    searches = UserSearch.where(ip_address: @ip_address)
                        .where('created_at > ?', 1.minute.ago)
    assert_equal 1, searches.count
    assert_equal "ruby on rails", searches.first.query
  end

  test "should remove duplicates after creation" do
    post search_queries_path,
         params: { query: "duplicate" },
         headers: { 'REMOTE_ADDR' => @ip_address }
    
    post search_queries_path,
         params: { query: "duplicate" },
         headers: { 'REMOTE_ADDR' => @ip_address }

    searches = UserSearch.where(
      ip_address: @ip_address,
      query: "duplicate"
    )
    assert_equal 1, searches.count
  end

  test "should get new with top queries" do
    get new_search_query_path
    assert_response :success
    assert_not_nil assigns(:queries)
    assert assigns(:queries).is_a?(Hash)
  end

  test "should return autocomplete suggestions" do
    get autocomplete_search_queries_path,
        params: { term: "ruby" },
        headers: { 'Accept' => 'application/json' }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response.is_a?(Array)
    assert json_response.any? { |query| query.include?("ruby") }
  end

  test "should get analytics as HTML" do
    get analitycs_search_queries_path
    assert_response :success
    assert_not_nil assigns(:analytics)
    assert assigns(:analytics).key?(:most_searched_terms)
    assert assigns(:analytics).key?(:recent_searches)
    assert assigns(:analytics).key?(:search_trends)
    assert assigns(:analytics).key?(:popular_phrases)
    assert assigns(:analytics).key?(:unique_users)
    assert assigns(:analytics).key?(:total_searches)
  end

  test "should get analytics as JSON" do
    get analitycs_search_queries_path,
        headers: { 'Accept' => 'application/json' }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert json_response.key?("most_searched_terms")
    assert json_response.key?("recent_searches")
    assert json_response.key?("search_trends")
    assert json_response.key?("popular_phrases")
    assert json_response.key?("unique_users")
    assert json_response.key?("total_searches")
  end

  test "analytics should return most searched terms" do
    get analitycs_search_queries_path,
        headers: { 'Accept' => 'application/json' }
    
    json_response = JSON.parse(response.body)
    most_searched = json_response["most_searched_terms"]
    
    assert most_searched.is_a?(Array)
    assert most_searched.length > 0
    assert most_searched.first.key?("term")
    assert most_searched.first.key?("count")
    
    # Should be ordered by count (descending)
    if most_searched.length > 1
      assert most_searched.first["count"] >= most_searched.second["count"]
    end
  end

  test "analytics should return recent searches" do
    get analitycs_search_queries_path,
        headers: { 'Accept' => 'application/json' }
    
    json_response = JSON.parse(response.body)
    recent_searches = json_response["recent_searches"]
    
    assert recent_searches.is_a?(Array)
    assert recent_searches.all? { |search| search.key?("term") && search.key?("count") }
  end

  test "analytics should return search trends" do
    get analitycs_search_queries_path,
        headers: { 'Accept' => 'application/json' }
    
    json_response = JSON.parse(response.body)
    search_trends = json_response["search_trends"]
    
    assert search_trends.is_a?(Hash)
    assert_equal 7, search_trends.keys.length
    
    # Should have dates as keys
    search_trends.keys.each do |date_key|
      assert_match(/\d{4}-\d{2}-\d{2}/, date_key)
    end
  end

  test "analytics should return popular phrases" do
    get analitycs_search_queries_path,
        headers: { 'Accept' => 'application/json' }
    
    json_response = JSON.parse(response.body)
    popular_phrases = json_response["popular_phrases"]
    
    assert popular_phrases.is_a?(Array)
    popular_phrases.each do |phrase|
      assert phrase.key?("phrase")
      assert phrase.key?("count")
      assert phrase["phrase"].length > 10
    end
  end

  test "analytics should return correct counts" do
    get analitycs_search_queries_path,
        headers: { 'Accept' => 'application/json' }
    
    json_response = JSON.parse(response.body)
    
    assert json_response["unique_users"].is_a?(Integer)
    assert json_response["total_searches"].is_a?(Integer)
    assert json_response["unique_users"] > 0
    assert json_response["total_searches"] > 0
  end

  private

  def create_test_searches
    # Create diverse test data
    ips = ["192.168.1.1", "192.168.1.2", "192.168.1.3"]
    queries = [
      "ruby programming",
      "rails framework",
      "javascript tutorial",
      "python basics",
      "web development guide",
      "database design patterns",
      "ruby",
      "rails",
      "js",
      "python"
    ]

    # Create searches with different timestamps
    queries.each_with_index do |query, index|
      ip = ips[index % ips.length]
      created_time = (index + 1).hours.ago
      
      # Create multiple instances of popular queries
      (3 - (index % 3)).times do
        UserSearch.create!(
          ip_address: ip,
          query: query,
          created_at: created_time + rand(60).minutes
        )
      end
    end
  end
end
