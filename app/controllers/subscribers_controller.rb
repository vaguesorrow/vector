class SubscribersController < ApplicationController
  def create
    if params[:consent] != "1"
      redirect_to root_path, alert: "Нужно согласие на обработку данных.", status: :see_other
      return
    end

    if params[:marketing_consent] != "1"
      redirect_to root_path, alert: "Нужно согласие на получение рассылки.", status: :see_other
      return
    end

    existing = NewsletterSubscriber.exists?(email: params[:email].to_s.strip.downcase)
    NewsletterSubscriber.subscribe!(email: params[:email].to_s,
      personal_data_consent: true, marketing_consent: params[:marketing_consent] == "1")

    if existing
      already_subscribed
    else
      redirect_to root_path, notice: "Спасибо! Вы подписались.", status: :see_other
    end
  rescue ActiveRecord::RecordInvalid
    subscription_failed
  rescue ActiveRecord::RecordNotUnique
    already_subscribed
  end

  private

  def already_subscribed
    redirect_to root_path, notice: "Вы уже подписались на уведомления", status: :see_other
  end

  def subscription_failed
    redirect_to root_path, alert: "Не удалось подписаться. Проверьте адрес.", status: :see_other
  end
end
