# app/services/application_service.rb
class ApplicationService
  def self.call(*args)
    new(*args).call
  end
end