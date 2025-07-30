
class SearchQueriesController < ApplicationController
    def create
        ip = request.remote_ip
        query = params[:query]
        UserSearch.create(ip_address: ip, query: query)
        UserSearch.clean_pyramid_queries_for(ip)
    end
    
    def new
        @queries = UserSearch.group(:query).order('count_query desc').limit(5).count(:query)
    end

    def analitycs
    end    
end
