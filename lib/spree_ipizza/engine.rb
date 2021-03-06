module SpreeIpizza
  class Engine < Rails::Engine
    engine_name 'spree_ipizza'

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
    end

    config.after_initialize do |app|
      app.config.spree.payment_methods += [
        Spree::Gateway::Seb,
        Spree::Gateway::Swedbank
      ]
    end

    config.to_prepare &method(:activate).to_proc
  end
end
