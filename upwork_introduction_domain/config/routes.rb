Rails.application.routes.draw do
	
	root to: "purchace_orders#index"
	resources :purchace_orders, except: [:destroy] do
		collection do
			post "free"
		end
	end
	resources :skus, except: [:destroy] do
		collection do
			post "free"
		end
	end

end
