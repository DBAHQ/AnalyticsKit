Pod::Spec.new do |s|
  s.name             = 'AnalyticsKit'
  s.version          = '0.2.1'
  s.summary          = 'Общий слой аналитики приложений DBAHQ.'
  s.description      = <<-DESC
                       Единый приёмник продуктовых событий: фанаут в Firebase, AppMetrica
                       и Adjust, жизненный цикл сессии, отметка install, события AppLovin
                       и батч-репортер дохода с рекламы на свой бекенд.
                       Всё прикладное — ключи, userID, язык, пуш-токен, карта токенов
                       Adjust — приложение передаёт через AnalyticsConfiguration.
                       DESC
  s.homepage         = 'https://github.com/DBAHQ/AnalyticsKit'
  s.license          = { :type => 'Proprietary', :file => 'LICENSE' }
  s.author           = { 'ak' => 'ak@ironsum.com' }
  s.source           = { :git => 'git@github.com:DBAHQ/AnalyticsKit.git', :tag => s.version.to_s }

  s.static_framework      = true
  s.ios.deployment_target = '15.0'
  s.swift_version         = '5.0'
  s.source_files          = 'AnalyticsKit/Classes/**/*.swift'

  s.dependency 'FirebaseAnalytics'
  # Явно, а не транзитивом из YandexMobileAds: реклама Yandex будет удалена,
  # аналитика AppMetrica остаётся.
  s.dependency 'AppMetricaCore'
  # Тот же сабспек, что в AdKit: обычный 'Adjust' с ним конфликтует.
  s.dependency 'Adjust/AdjustGoogleOdm'
  s.dependency 'AppLovinSDK'
end
