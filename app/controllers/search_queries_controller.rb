class SearchQueriesController < ApplicationController
    def create
        ip = request.remote_ip
        query = params[:query]
        UserSearch.create(ip_address: ip, query: query)
        UserSearch.clean_pyramid_queries_for(ip)
        UserSearch.remove_duplicates_for(ip)
    end
    
    def new
        @queries = UserSearch.group(:query).order('count_query desc').limit(5).count(:query)
    end

    def autocomplete
        term = params[:term]
        queries = UserSearch.where("query LIKE ?", "#{term}%")
                       .group(:query)
                       .order('count_query desc')
                       .limit(5)
                       .count(:query)
                       .keys
        render json: queries
    end

    def analitycs
        @analytics = {
            most_searched_terms: most_searched_terms,
            recent_searches: recent_searches,
            search_trends: search_trends,
            popular_phrases: popular_phrases,
            unique_users: unique_users_count,
            total_searches: total_searches_count
        }
        
        respond_to do |format|
            format.html
            format.json { render json: @analytics }
        end
    end
    
    private
    
    def most_searched_terms
        UserSearch.group(:query)
                  .order('count_query desc')
                  .limit(10)
                  .count(:query)
                  .map { |query, count| { term: query, count: count } }
    end
    
    def recent_searches
        UserSearch.where(created_at: 24.hours.ago..Time.current)
                  .group(:query)
                  .order('count_query desc')
                  .limit(10)
                  .count(:query)
                  .map { |query, count| { term: query, count: count } }
    end
    
    def search_trends
        trends = {}
        7.times do |i|
            date = i.days.ago.beginning_of_day
            end_date = date.end_of_day
            
            count = UserSearch.where(created_at: date..end_date).count
            trends[date.strftime('%Y-%m-%d')] = count
        end
        trends.sort.reverse.to_h
    end
    
    def popular_phrases
        phrases = UserSearch.where('LENGTH(query) > ?', 10)
                           .group(:query)
                           .order('count_query desc')
                           .limit(10)
                           .count(:query)
                           .map { |query, count| { phrase: query, count: count } }
        phrases
    end
    
    def unique_users_count
        UserSearch.distinct.count(:ip_address)
    end
    
    def total_searches_count
        UserSearch.count
    end    
end
