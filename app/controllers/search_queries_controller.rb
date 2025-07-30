
class SearchQueriesController < ApplicationController
    def create
        ip = request.remote_ip
        query = params[:query]
        UserSearch.create(ip_address: ip, query: query)
    end
    
    def new
    end
    def analitycs
    end    
end
