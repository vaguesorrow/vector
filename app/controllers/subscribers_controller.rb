class SubscribersController < ApplicationController
  def create
    if params[:consent] != "1"
      redirect_to root_path, alert: "Нужно согласие на обработку данных.", status: :see_other
      return
    end

    subscriber = Subscriber.new(email: params[:email].to_s.strip.downcase,
      personal_data_consent_at: Time.current,
      marketing_consent_at: params[:marketing_consent] == "1" ? Time.current : nil)

    if subscriber.save
      redirect_to root_path, notice: "Спасибо! Вы подписались.", status: :see_other
    elsif subscriber.errors.of_kind?(:email, :taken)
      already_subscribed
    else
      subscription_failed
    end
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
