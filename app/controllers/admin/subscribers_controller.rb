module Admin
  class SubscribersController < BaseController
    def index
      @total = NewsletterSubscriber.count
      @page = [ params[:page].to_i, 1 ].max
      records = NewsletterSubscriber.order(created_at: :desc, id: :desc)
        .offset((@page - 1) * 30).limit(31).to_a
      @more = records.size > 30
      @subscribers = records.first(30)
    end
  end
end
