module CommonActions
	include Rails.application.routes.url_helpers

	def self.clear_temp_objects(params = {})
		PoHeader.where(po_identifier: UNASSIGNED).destroy_all
		SoHeader.where(so_identifier: UNASSIGNED).destroy_all
	end

	def self.object_crud_paths(show_path, edit_path, delete_path, others = [])
		paths = ""
		paths += "<a href='#{show_path}' class='btn-action glyphicons eye_open btn-default'><i></i></a> " if show_path
		paths += "<a href='#{edit_path}' class='btn-action glyphicons pencil btn-success'><i></i></a> " if edit_path
		paths += "<a href='#{delete_path}' class='btn-action glyphicons remove_2 btn-danger' rel='nofollow' data-method='delete' data-confirm='Are you sure?'><i></i></a> " if delete_path
		others.each do |other|
			unless other.nil?
				other[:method] ||= "get"
				paths += "<a href='#{other[:path]}' class='btn btn-mini btn-orange' data-method='#{other[:method]}'>#{other[:name]}</a> "
			end
		end
		paths
	end

	def self.get_quality_lot_div(soLineId)
		divdata = "<div class='so_line_lot_input'><select class='quality_lot' name='quality_lot_id' onchange='setLocation(this, #{soLineId})'>"
        if soLineId.present?
            # quality_lots = SoLine.find(soLineId).item.quality_lots.map { |x| (x && x.quantity_on_hand && x.quantity_on_hand > 0) ? [x.id,x.lot_control_no] : [] }
             so_line =  SoLine.find(soLineId)
             if so_line.item.present?
	            quality_lots = so_line.item.quality_lots.where('finished not in (?)', [true]).map { |x|  [x.id,x.lot_control_no]  }
	            quality_lots.each do |quality_lot|
	            	divdata += "<option value='#{quality_lot[0]}'>#{quality_lot[1]}</option>"
	            end
       		end
        end
		divdata += "</select></div>"
		divdata
	end
	def self.get_location_div(soLineId)
        if soLineId.present?
            # quality_lots = SoLine.find(soLineId).item.quality_lots.map { |x| (x && x.quantity_on_hand && x.quantity_on_hand > 0) ? [x.id,x.lot_control_no] : [] }
             so_line =  SoLine.find(soLineId)
             if so_line.item.present?
	            quality_lot = so_line.item.quality_lots.where('finished not in (?)', [true]).first
	            po_shipment = quality_lot.po_shipment if quality_lot
      			location = po_shipment.nil? ? "-" : po_shipment.po_shipped_unit.to_s + " - " + po_shipment.po_shipped_shelf
				location_div =  "<div id='location_#{soLineId}'>#{location}</div>"
       		end
        end
		location_div
	end

    def self.check_boxes(val, chkId, funct)
   		"<input type='checkbox' id='#{chkId}'  value='#{val}' onclick='#{funct}' >"
    end


	def self.linkable(path, title, extras = {})
		"<a href='#{path}'>#{title}</a>"
	end


	def self.nil_or_blank(attribute)
		attribute.nil? || attribute.eql?("")
	end


	def self.update_gl_accounts_for_gl_entry(title, op, amount)
    	gl_account = GlAccount.where('gl_account_title' => title ).first
		if op == 'increment'
			gl_amount = gl_account.gl_account_amount + amount
		elsif op == 'decrement'
			gl_amount = gl_account.gl_account_amount - amount
		end
         gl_account.update_attributes(gl_account_amount: gl_amount )
    end

	def self.process_application_shortcuts(shortcuts_html, shortcuts)
		shortcuts.each do |shortcut|
			unless shortcut[:drop_down]
				shortcuts_html += '<li><a class="'+ shortcut[:class] + '" href="' + shortcut[:path] + '"><i></i>' + shortcut[:name] + '</a>'
			else
				shortcuts_html += '<li class="dropdown submenu">'
				shortcuts_html += '<a href="' + shortcut[:path] + '" class="dropdown-toggle ' + shortcut[:class] + '" data-toggle="dropdown"><i></i>' + shortcut[:name] + '</a>'
				shortcuts_html += '<ul class="dropdown-menu submenu-show submenu-hide pull-left">'
				shortcuts_html += CommonActions.process_application_shortcuts('', shortcut[:sub_menu])
				shortcuts_html += '</ul>'
			end
		end
		shortcuts_html += '</li>' if shortcuts.count > 0
		shortcuts_html
	end


	def self.record_ownership(record, current_user)
		if record.new_record?
			record.created_by = current_user
		else
			record.updated_by = current_user
		end
		record
	end


	def self.current_hour_letter
		hour_letter = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X"]
		hour_letter[Time.now.hour]
	end


	private


	def after_sign_in_path_for(user)
		account_dashboard_path
	end

	def initialize_request
		unless params[:controller] == "rails_admin/main"
			params[:layout] = params[:layout] == "false" ? false : true
			@home = {:name => CompanyInfo.first ? CompanyInfo.first.company_name : "Alliance Fasteners"}
			@menus = application_main_menu
			@shortcuts = application_shortcuts
		end
	end


	def render_error(status, exception)
		case status
		when 500
			render static_pages_error_500_path , :layout => false, :status => :not_found

		when 404
			render static_pages_error_404_path , :layout => false, :status => :not_found

		else
		end
	end


	def application_main_menu
		menus = {}
		menus[:dashboard] = {:class => "glyphicons dashboard", :path => account_dashboard_path, :name => "Dashboard", :type => "single"}

		if  user_signed_in? &&  !current_user.is_customer? && !current_user.is_vendor?
			menus[:contacts] = {:class => "hasSubmenu glyphicons adress_book", :path => "#", :name => "Organizations", :type => "multiple"}
			menus[:contacts][:sub_menu] = 	[
				{:path => organizations_path, :name => "Companies"},
				{:path => contacts_path, :name => "Contacts"},
				{:path => groups_path, :name => "Group"},
			]
		end

		if  user_signed_in? &&  !current_user.is_logistics? && !current_user.is_quality?
			menus[:quotes] = {:class => "hasSubmenu glyphicons notes", :path => '#' , :name => "Quotes", :type => "multiple"}

			menus[:quotes][:sub_menu] = 	[]

			if can? :view, Quote
				menus[:quotes][:sub_menu].push({:path => quotes_path, :name => "Vendor Quotes"})
			end

			if can? :view, CustomerQuote
				menus[:quotes][:sub_menu].push({:path => customer_quotes_path, :name => "Customer Quotes"})
			end

		end

    if  user_signed_in? && !current_user.is_customer?
			menus[:purchases] = {:class => "hasSubmenu glyphicons cart_in", :path => "#", :name => "Purchases", :type => "multiple"}
			menus[:purchases][:sub_menu] = 	[
				{:path => po_headers_path, :name => "Purchase Orders"}
			]
		end

		if  user_signed_in? && !current_user.is_vendor?
			menus[:sales] = {:class => "hasSubmenu glyphicons stats", :path => "#", :name => "Sales", :type => "multiple"}
			menus[:sales][:sub_menu] = 		[
				{:path => so_headers_path, :name => "Sales Orders"}
			]
		end

		menus[:inventory] = {:class => "hasSubmenu glyphicons cargo", :path => "#", :name => "Inventory", :type => "multiple"}
		menus[:inventory][:sub_menu] = 	[
			{:path => items_path, :name => "Items"},
			{:path => item_alt_names_path, :name => "Alternates"},
			{:path => inventory_adjustments_path, :name => "Adjust Inventory"},
			{:path => prints_path, :name => "Prints"},
			{:path => elements_path, :name => "Elements"}
		]

		if can? :view, Material
			menus[:inventory][:sub_menu].push({:path => materials_path, :name => "Materials"})
		end

		if can? :view, ProcessType
			menus[:inventory][:sub_menu].push({:path => process_types_path, :name => "Processes"})
		end
		if can? :view, Specification
			menus[:inventory][:sub_menu].push({:path => specifications_path, :name => "Specifications"})
		end

		if  user_signed_in? &&  !current_user.is_logistics? && !current_user.is_quality? && !current_user.is_customer? && !current_user.is_vendor?
			menus[:accounts] = {:class => "hasSubmenu glyphicons book", :path => "#", :name => "Accounts", :type => "multiple"}
			menus[:accounts][:sub_menu] = 	[
				{:path => payables_path, :name => "Payables"},
				{:path => payments_path, :name => "Payments"},
				{:path => receivables_path, :name => "Invoice"},
				{:path => receipts_path, :name => "Receipts"}
			]
		end

		if  user_signed_in? && !current_user.is_customer?
			menus[:general_ledger] = {:class => "hasSubmenu glyphicons book_open", :path => "#", :name => "General Ledger", :type => "multiple"}
			menus[:general_ledger][:sub_menu] = 	[]

        if can? :view, GlEntry
          menus[:general_ledger][:sub_menu].push({:path => new_gl_entry_path, :name => "Journal Entries"})
        end

        menus[:general_ledger][:sub_menu].push({:path => check_registers_path, :name => "Check Register"})
        menus[:general_ledger][:sub_menu].push({:path => credit_registers_path, :name => "Credit Register"})

        if can? :view, Reconcile
          menus[:general_ledger][:sub_menu].push({:path => reconciles_path, :name => "Reconcile"},)
        end

        if can? :view, GlAccount
          menus[:general_ledger][:sub_menu].push({:path => gl_accounts_path, :name => "Accounts"})
        end

        menus[:general_ledger][:sub_menu].push({:path => gl_types_path, :name => "Account Types"})

      end


		menus[:quality] = {:class => "hasSubmenu glyphicons log_book", :path => "#", :name => "Quality", :type => "multiple"}

  		menus[:quality][:sub_menu] = 	[]

  		if can? :view, QualityLot
  			menus[:quality][:sub_menu].push({:path => quality_lots_path, :name => "Lot Info"})
  		end

  		menus[:quality][:sub_menu].push({:path => process_flows_path, :name => "Process Flow"})
  		menus[:quality][:sub_menu].push({:path => fmea_types_path, :name => "FMEA"})
  		menus[:quality][:sub_menu].push({:path => control_plans_path, :name => "Control Plan"})
      menus[:quality][:sub_menu].push({:path => capacity_plannings_path, :name => "Capacity Planning"})

  		if can? :view, Package
  			menus[:quality][:sub_menu].push({:path => packages_path, :name => "Packaging"})
  		end

  		if can? :view, RunAtRate
  			menus[:quality][:sub_menu].push({:path => run_at_rates_path, :name => "Run at Rate"})
  		end

      menus[:quality][:sub_menu].push({:path => quality_actions_path, :name => "Quality Action"})

  		if can? :view, CauseAnalysis
  			menus[:quality][:sub_menu].push({:path => cause_analyses_path, :name => "Cause Analysis"})
  		end

  		if can? :view, CustomerFeedback
  			menus[:quality][:sub_menu].push({:path => customer_feedbacks_path, :name => "Customer Response"})
  		end

  		if can? :view, Gauge
  			menus[:quality][:sub_menu].push({:path => gauges_path, :name => "Instruments"})
  		end

      if can? :view, Dimension
        menus[:quality][:sub_menu].push({:path => dimensions_path, :name => "Dimension Types"})
    	end

      if  user_signed_in? && !current_user.is_vendor? && !current_user.is_customer?
       menus[:quality][:sub_menu].push({:path => customer_qualities_path, :name => "Quality Level"})
      end

      menus[:quality][:sub_menu].push({:path => vendor_qualities_path, :name => "Quality ID"})

		if  user_signed_in? && !current_user.is_vendor?  && !current_user.is_customer?
			menus[:logistics] = {:class => "hasSubmenu glyphicons boat", :path => "#", :name => "Logistics", :type => "multiple"}
			menus[:logistics][:sub_menu] = 	[
				{:path => new_po_shipment_path, :name => "Receiving"},
				{:path => new_so_shipment_path, :name => "Shipping"},
				{:path => so_shipments_path(type: "process"), :name => "In Process"},
				{:path => po_shipments_path(type: "history"), :name => "History"}
			]
		end

		menus[:reports] = {:class => "hasSubmenu glyphicons charts", :path => "#", :name => "Reports", :type => "multiple"}
		menus[:reports][:sub_menu] = 	[
			{:path => gauges_path(type: "gauge"), :name => "Gauge Calibration"},
			{:path => organizations_path(type1: "vendor",type2: "certification"), :name => "Vendor Qualification"},
			{:path => new_so_shipment_path(type1: "shipping_to",type2: "due_date"), :name => "Shipping Due"},
			{:path => quality_lots_path(type: "lot_missing_location"), :name => "Lots Missing Location"}

		]

		menus[:documentation] = {:class => "hasSubmenu glyphicons briefcase", :path => "#", :name => "Documentation", :type => "multiple"}
		menus[:documentation][:sub_menu] = 	[
			{:path => "#", :name => "Internal"},
			{:path => "#", :name => "Vendor"},
			{:path => "#", :name => "Customer"},
			{:path => "#", :name => "General"},
			{:path => quality_documents_path, :name => "Quality Level Documents"}


		]

		menus[:system] = {:class => "hasSubmenu glyphicons cogwheels", :path => "#", :name => "System", :type => "multiple"}

		menus[:system][:sub_menu] = 	[]

      menus[:system][:sub_menu].push({:path => events_path, :name => "Calendar"})

      menus[:system][:sub_menu].push({:path => commodities_path, :name => "Commodities"})


  		if can? :view, Territory
  			menus[:system][:sub_menu].push({:path => territories_path, :name => "Territories"})
  		end

  		if can? :view, Owner
  			menus[:system][:sub_menu].push({:path => owners_path, :name => "Owners"})
  		end

      menus[:system][:sub_menu].push({:path => check_code_path(CheckCode.first), :name => "Counters"})

  		if can? :view, User
  			menus[:system][:sub_menu].push({:path => privileges_path, :name => "Privileges"})
  		end

  		if can? :view, CompanyInfo
  			menus[:system][:sub_menu].push({:path => company_infos_path, :name => "Home Info"})
  		end

		menus
	end


	def application_shortcuts
		[	{:name => "System", :class => "glyphicons cogwheels", :drop_down => true, :path => "#",
			 :sub_menu => [
				 {:path => company_infos_path, :name => "Company Info", :class => "", :drop_down => false, :sub_menu => []},
				 {:path => owners_path, :name => "Owners", :class => "", :drop_down => false, :sub_menu => []},
				 {:path => territories_path, :name => "Territories", :class => "", :drop_down => false, :sub_menu => []},
				 {:path => commodities_path, :name => "Commodities", :class => "", :drop_down => false, :sub_menu => []}
				 # {:path => specifications_path, :name => "Specifications", :class => "", :drop_down => false, :sub_menu => []},
				 # {:path => materials_path, :name => "Materials", :class => "", :drop_down => false, :sub_menu => []},
				 # {:path => process_types_path, :name => "Processes", :class => "", :drop_down => false, :sub_menu => []},
				 # {:path => vendor_qualities_path, :name => "Quality ID", :class => "", :drop_down => false, :sub_menu => []},
				 # {:path => customer_qualities_path, :name => "Quality Level", :class => "", :drop_down => false, :sub_menu => []},
			 ]
			 }
			]
	end


	def self.get_new_identifier(model, field, letter)
		max_identifier = model.maximum(field)
		if max_identifier.nil?
			letter + "00001"
		elsif (cur_identifier = max_identifier[1..5].to_i + 1) > 99999
			letter + "00001"
		else
			letter + "%05d" % cur_identifier
		end
	end

	def self.highlighted_text(string)
		"<div style='color:red'>#{string}</div>".html_safe
	end

	def self.status_color(status)
		if status == "won"
			"<div style='color:green'>#{status.capitalize}</div>".html_safe
		elsif status == "lost"
			"<div style='color:red'>#{status.capitalize}</div>".html_safe
		elsif status == "open"
			"<div>#{status.capitalize}</div>".html_safe
		end

	end

	def self.set_quality_status(status)
		if status == "open"
			"<div style='color:yellow'>#{status.capitalize}</div>".html_safe
		elsif status == "finished"
			"<div style='color:green'>#{status.capitalize}</div>".html_safe
		end
	end

	def self.process_application_notifications(user_id)
		temp = source = ''
		user = User.find(user_id)
		quality_user = User.where(:roles_mask => 4).first
		user.quality_actions.each do |quality_action|
			notification = notification_check_status(quality_action,"QualityAction",user)
			if notification.present?
				temp = "<li id="+notification.first.id.to_s+"><a href='/quality_actions/"+quality_action.id.to_s+"' class='glyphicons envelope'><i></i>"+quality_action.quality_action_no.to_s+"-Quality Action Assigned to you </a></li>"
				source += temp
			end
		end

		if User.current_user.present? && User.current_user.is_quality?
		 	vendor_organizations = Organization.where("vendor_expiration_date >= ? AND vendor_expiration_date <= ? AND organization_type_id = ?",Date.today, Date.today+29, 6)
		 	vendor_organizations.each do |vendor_organization|
		 		if vendor_organization.present?
		 			notification = notification_check_status(vendor_organization,"Organization",quality_user)
		 			if notification.present?
		 				temp = "<li id="+notification.first.id.to_s+"><a href='/organizations/"+vendor_organization.id.to_s+"' class='glyphicons envelope'><i></i>Certifications are about to expire</a></li>"
						source += temp
					end
		 		end
		 	end

		 	prints = Print.all
		 	prints.each do |print|
		 		if print.present?
		 			notification = notification_check_status(print,"Print",quality_user)
		 			if notification.present?
		 				temp = "<li id="+notification.first.id.to_s+"><a href='/prints/"+print.id.to_s+"' class='glyphicons envelope'><i></i>"+print.print_identifier+"-print created</a></li>"
						source += temp
					end
		 		end
		 	end

		 	specifications = Specification.all
		 	specifications.each do |specification|
		 		if specification.present?
		 			notification = notification_check_status(specification,"Specification",quality_user)
		 			if notification.present?
		 				temp = "<li id="+notification.first.id.to_s+"><a href='/specifications/"+specification.id.to_s+"' class='glyphicons envelope'><i></i>"+specification.specification_identifier+"-specification created</a></li>"
						source += temp
					end
		 		end
		 	end

		 	process_types = ProcessType.all
		 	process_types.each do |process_type|
		 		if process_type.present?
		 			notification = notification_check_status(process_type,"ProcessType",quality_user)
		 			if notification.present?
		 				temp = "<li id="+notification.first.id.to_s+"><a href='/process_types/"+process_type.id.to_s+"' class='glyphicons envelope'><i></i>"+process_type.process_short_name+"-process_type created</a></li>"
						source += temp
					end
		 		end
		 	end

		 	po_lines = PoLine.all
		 	po_lines.each do |po_line|
		 		if po_line.present?
		 			notification = notification_check_status(po_line,"PoLine",quality_user)
		 			if notification.present?
	 					temp = "<li id="+notification.first.id.to_s+"><a href='/po_headers/"+po_line.po_header.id.to_s+"' class='glyphicons envelope'><i></i>PO "+po_line.po_header.po_identifier+" bypassed supplier requirements</a></li>"
						source += temp
					end
		 		end
		 	end
		end

		source
	end

	def self.notification_check_status(note_id,note_type,u_id)
		if Notification.where(:notable_id => note_id.id).present?
			Notification.where("notable_id =? AND notable_type =? AND user_id =? AND note_status =? ", note_id.id, note_type, u_id.id, "unread")
		end
	end

	def self.notification_process(model_type, model_id)
		quality_user = User.where(:roles_mask => 4).first

      if model_type == "Organization" && model_id.organization_type_id == 6
      	common_process_model(model_type,model_id,quality_user)

      elsif model_type == "QualityAction"
      	if model_id.users.present?
            model_id.users.each do |user|
                notification_set_status(model_id,model_type,user.id)
            end
      	end

      elsif model_type == "Print"
     		common_process_model(model_type,model_id,quality_user)

      elsif model_type == "Specification"
    		common_process_model(model_type,model_id,quality_user)

      elsif model_type == "ProcessType"
     		common_process_model(model_type,model_id,quality_user)

     	elsif model_type == "PoLine"
     		if model_id.organization.present? && model_id.organization.min_vendor_quality.quality_name.ord <= model_id.po_header.organization.vendor_quality.quality_name.ord
     			common_process_model(model_type,model_id,quality_user)
     		end
      end
    end

    def self.common_process_model(model, model_note, user)
    	if user.present?
        	notification_set_status(model_note,model,user.id)
       	end
    end

    def self.notification_set_status(model_identifier,model_type_name,user_id)
    	notification = Notification.find_by_notable_id(model_identifier.id)
    	unless notification.present?
    		notification = Notification.create(notable_id: model_identifier.id, notable_type:  model_type_name, note_status:  "unread", user_id:  user_id)
    		notification.save
    	else
    		notification.update_attributes(:note_status => "unread")
    	end
    end
end