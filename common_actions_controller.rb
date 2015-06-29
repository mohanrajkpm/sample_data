class CommonActionsController < ApplicationController
    def get_info
      # result = []
        case(params[:mode])
            when "po_line_revisions"
              po_line = PoLine.find(params[:id])
              result = {}
              result[:aaData] = po_line.present? ? po_line.item.item_revisions : []
              result[:default] = (po_line.present? && po_line.item.current_revision.present?) ? po_line.item.current_revision.id : 0
              latest_received = po_line.po_shipments.order(:created_at).last
              result[:latest_received_count] = latest_received.present? ? latest_received.po_shipped_count : ""

            when "po_header_items"
              po_header = PoHeader.find(params[:id])
              result = po_header.present? ? po_header.po_lines : []
              result = result.each {|line| line[:po_line_item_name] = line.po_line_item_name }

            when "get_quality_lots_inventory"
              if params[:id].present?
                item_alt_name = ItemAltName.find(params[:id])
                result = item_alt_name.present? ? item_alt_name.item.quality_lots : []
                result = result.each {|line| line[:lot_control_no] = line.lot_control_no }
              end

            when "get_process_types_po"
              if params[:id].present?
                item_alt_name = ItemAltName.find(params[:id])
                result = item_alt_name.present? ? item_alt_name.item.item_revisions.last.process_types : []
                result = result.each {|line| line[:process_short_name] = line.process_short_name }
              end
            when "set_notification_status"
              if params[:id].present?
                Notification.find(params[:id]).update_attributes(:note_status => "read")
                result = "success"
              end

            when "initiate_notifications"
              if params[:user_id].present?


                # notification_list = {}
                # source = temp = ''
                # User.find(params[:user_id]).quality_actions.each do |quality_action|
                #   temp = '<li><a href="/quality_actions/'+quality_action.id.to_s+'" class="glyphicons envelope"><i></i>Quality Action #1234 Assigned to you</a></li>'
                #   source += temp
                # end

                # notification_list["list"] = source

                # result =  notification_list["list"] 
              end
            when "org_contact_mail"
              if params[:organization_id].present?
                organization = Organization.find(params[:organization_id])
                result = organization.present? ? organization.contacts : []
                result = result.each {|line| line[:contact_email] = line.contact_email }
              end

            when "org_head_mail"
              if params[:organization_id].present?
                organization = Organization.find(params[:organization_id])
                org = {}
                if organization.present?
                  org['id'] = organization.id
                  org['Email'] = organization.organization_email
                end
                result = org
              end


            when "get_quality_lot_current_quantity"
              if params[:id].present?
                quality_lot = QualityLot.find(params[:id])
                result = quality_lot
              end
            when "set_lot_status_history"
              if params[:id].present? && params[:user_id].present? && params[:lot_status].present?
                quality_history = QualityHistory.create(quality_lot_id: params[:id], quality_status: params[:lot_status], user_id: params[:user_id])
                result = quality_history.quality_status if quality_history.quality_status
              else
                result = "fail"
              end
            when "get_lot_status_history"
              if params[:id].present?
                quality_histories = QualityHistory.lot_all_status(params[:id])
                result = quality_histories
              end

            when "get_org"
              if params[:so_value].present?
                organization =  Organization.find_by_organization_name(params[:so_value])
                result = organization              
              end

            when "get_item"
              if params[:item_name].present?
                item =  Item.find_by_item_part_no(params[:item_name])
                result = item              
              end
              

            when "get_account"
              if params[:gl_name].present?
                account =  GlAccount.find_by_gl_account_title(params[:gl_name])
                result = account              
              end
            when "get_po"
              if params[:po_name].present?
                po_header =  PoHeader.find_by_po_identifier(params[:po_name])
                result = po_header              
              end
            when "get_cause"
              if params[:cause_name].present?
                cause_analysis = CauseAnalysis.find_by_name(params[:cause_name])
                result = cause_analysis              
              end

             when "get_lot"
              if params[:lot_name].present?
                quality_lot = QualityLot.find_by_lot_control_number(params[:lot_name])
                result =  quality_lot             
              end             
              

            when "get_alt_name"
              if params[:value].present?
                item =  Item.find_by_item_part_no(params[:value])
                alt_name_item = item.item_alt_names.first
                result = alt_name_item              
              end

            when "get_location"
              if params[:lot_id] && params[:line_id]
                res = Hash.new
                quality_lot = QualityLot.find(params[:lot_id])
                po_shipment = quality_lot.po_shipment if quality_lot
                location = po_shipment.nil? ? "-" : po_shipment.po_shipped_unit.to_s + " - " + po_shipment.po_shipped_shelf
                res["location"] = location
                res["line_id"] = params[:line_id]
                result = res
              end


            when "lot_item_material_elements"
              lot = QualityLot.find(params[:id])
              result = lot.lot_item_material_elements
              result = result.each {|line| line[:element_with_symbol] = line.element_with_symbol }

            when "lot_item_dimensions"
              lot = QualityLot.find(params[:id])
              result = lot.lot_item_dimensions

            when "material_element_info"
              result = MaterialElement.find(params[:id])

            when "organization_payables"
              organization = Organization.find(params[:id])
              result = organization.present? ? organization.payables.where(:payable_status => "open") : []

            when "organization_receivables"
              organization = Organization.find(params[:id])
              result = organization.present? ? organization.receivables.where(:receivable_status => "open") : []

            when "payment_payable_info"
              payable = Payable.find(params[:id])
              payable["payable_balance"] = payable.payable_current_balance
              result = payable

            when "receipt_receivable_info"
              receivable = Receivable.find(params[:id])
              receivable["receivable_balance"] = receivable.receivable_current_balance
              result = receivable

            when "organization_open_pos"
              organization = Organization.find(params[:id])
              result = organization.present? ? organization.purchase_orders.where(:po_status => "open") : []

            when "create_payable"
              if params[:id].present?
                payable = Payable.find(params[:id])
                if payable.update_attributes(:payable_disperse => "unassigned")
                  result = "success"  
                end             
              end
              # puts params[:shipments].to_s
              # PoHeader.process_payable_po_lines(params)
            when "create_receivable"
              if params[:id].present?
                receivable = Receivable.find(params[:id])
                if receivable.update_attributes(:receivable_disperse => "unassigned")
                  result = "success"  
                end             
              end

            when "send_quotes_mail"

              if params[:contact_id].present? && params[:quote_id].present? && params[:organization_id].present?                  
                quote = Quote.find(params[:quote_id])
                organization = Organization.find(params[:organization_id])
                # quote.quote_vendors.each do |quote_vendor|
                  if organization.contact_type.type_name == "Email"
                    email = (params[:contact_id] == params[:organization_id]) ? organization.organization_email : Contact.find(params[:contact_id]).contact_email
                    UserMailer.send_quote(quote,email).deliver
                  end
                # end
                result = "success"

               else
                result = "fail"
               end

            when "send_po_order_mail"
              val =  params[:organizations]
              @po_header = PoHeader.find(params[:po_header_id])
              @contact = Contact.find(val["0"]["value"].to_i)
              @vendor_email = @contact.contact_email
              if @vendor_email.present?
                UserMailer.purchase_order_mail(@po_header, @vendor_email).deliver
                result = "success"
              else
                   result = "fail"
              end 
              
            when "shipment_process_complete"
              if params[:shipment_process_id].present?
                  so_shipment_process = SoShipment.where(:shipment_process_id => params[:shipment_process_id],:so_shipped_status => ['process', 'ship_close','ship_in'])
                  so_shipment = {}
                  item_part = temp = source = item_desc  = item_qty = item_shipped = item_alt_part = item_lot = content = so_total =  notes = cusomter_po = ""
                  so_b_c_title = so_b_c_address_1 = so_b_c_address_2 = so_b_c_state = so_b_c_country = so_b_c_zipcode = ''
                  so_s_c_title = so_s_c_address_1 = so_s_c_address_2 = so_s_c_state = so_s_c_country = so_s_c_zipcode = ''
                  if so_shipment_process.count > 0

                    i = 1
                    j = 1
                    flag = 1
                    flag2 = 1

                    @so_header = SoHeader.find(so_shipment_process.last.so_header_id)

                    if @so_header.bill_to_address.present? 
                      so_b_c_title = @so_header.bill_to_address.contact_title 
                      so_b_c_address_1 = @so_header.bill_to_address.contact_address_1 
                      so_b_c_address_2 = @so_header.bill_to_address.contact_address_2 
                      so_b_c_state = @so_header.bill_to_address.contact_state 
                      so_b_c_country = @so_header.bill_to_address.contact_country 
                      so_b_c_zipcode = @so_header.bill_to_address.contact_zipcode
                    end 
                    if @so_header.ship_to_address.present? 
                      so_s_c_title= @so_header.ship_to_address.contact_title 
                      so_s_c_address_1 = @so_header.ship_to_address.contact_address_1 
                      so_s_c_address_2 = @so_header.ship_to_address.contact_address_2 
                      so_s_c_state = @so_header.ship_to_address.contact_state 
                      so_s_c_country = @so_header.ship_to_address.contact_country 
                      so_s_c_zipcode = @so_header.ship_to_address.contact_zipcode
                    end 
                    cusomter_po =   @so_header.so_header_customer_po if @so_header.so_header_customer_po.present? 

                    notes = @so_header.so_notes if @so_header.so_notes
                    so_total = (@so_header.so_total.to_f).to_s
                    len = so_shipment_process.group(:so_line_id).length
                    @company_info = CompanyInfo.first

                    so_shipment_process.group(:so_line_id).each_with_index do |shipment, index| 
                      item_part = shipment.so_line.item.item_part_no
                      item_desc = shipment.so_line.item_revision.item_description if shipment.so_line.item_revision.item_description.present? 
                      item_qty = shipment.so_line.so_line_quantity.to_s
                      item_shipped = SoShipment.where(:so_line_id =>  shipment.so_line, :so_shipped_status => ['process', 'ship_close','ship_in']).sum(:so_shipped_count).to_s
                      # item_alt_part = shipment.so_line.item_alt_name.item_alt_identifier if shipment.so_line.item.item_part_no != shipment.so_line.item_alt_name.item_alt_identifier 
                      item_lot = shipment.quality_lot.lot_control_no if shipment.quality_lot
                      temp = '<tr align="center"><td id="pk100_part_no" scope="row">' +item_part+'<table><tr><td align="center" id="pk100_alt_part_no">'+item_alt_part+'</td></tr><tr> <td align="center" id="pk100_control_no">'+item_lot+'</td></tr></table></td><td id="pk100_part_description">'+item_desc+'</td><td class="text-6" id="pk100_so_qty">'+item_qty+'</td><td id="pk100_shipped_part">'+item_shipped+'</td></tr>'
                      source += temp

                      if i== 1  
                        content += '<div class="ms_wrapper"><section><article><div class="ms_image-5"><div class="ms_image-wrapper"><img alt=Report_heading src=http://erp.chessgroupinc.com/'+@company_info.logo.joint.url(:original)+' /></div><div class="ms_image-text"><h5>'+@company_info.company_address1+'<br/>'+@company_info.company_address2+'<hr><b>P:&nbsp;</b>'+@company_info.company_phone1+'<br/>&nbsp;<b>F:&nbsp;</b>'+@company_info.company_fax+'<hr></h5></div></div><div class="ms_image-3"><h3>Packing Slip Number</h3><h2>'+ @so_header.so_identifier+'</h2><h5> Sales Order Date :'+@so_header.created_at.strftime("%m/%d/%Y")+'</h5><h5>Customer P.O: '+cusomter_po+'</h5></div></article>'
                        if flag ==1
                          content += '<article><div class="ms_text"><h1 class="ms_heading">Bill To :</h1> <h2 class="ms_sub-heading">'+so_b_c_title+'</h2> <h6> '+so_b_c_address_1+'</h6> <h6>'+so_b_c_address_2+'</h6><h6>'+so_b_c_state+'</h6><div class="dd"><h6 class="ds">'+so_b_c_country+'</h6>   <span id ="pk100_so_b_c_zipcode">'+so_b_c_zipcode+'</span></div></div><div class="ms_text-2"><h1 class="ms_heading">Ship To : </h1> <h2 class="ms_sub-heading" id="pk100_so_s_c_title">'+so_s_c_title+'</h2> <h6 id ="pk100_so_s_c_address_1">'+so_s_c_address_1+'</h6> <h6 id="pk100_so_s_c_address_2">'+so_s_c_address_2+'</h6><h6 id="pk100_so_s_c_state">'+so_s_c_state+'</h6><div class="dd"><h6 id="pk100_so_s_c_country"  class="ds">'+so_s_c_country+'</h6>   <span id ="pk100_so_s_c_zipcode" class="ss">'+so_s_c_zipcode+'</span></div></div></article>' 
                          flag =0;
                        end

                        if flag2 ==1
                          content += '<div class="b_content">  <table width="100%" border="0" cellspacing="0" cellpadding="0"><tr align="center" class="fon-004"><td width="28%">CUST P/N - ALL P/N</td><td width="28%">Description</td><td width="29%">QTY</td><td width="30%">Shipped</td></tr>'
                          flag2=0;
                        else
                          content += '<div class="c_content"> <table width="100%" border="0" cellspacing="0" cellpadding="0"><tr align="center" class="fon-004"><td width="28%">CUST P/N - ALL P/N</td><td width="28%">Description</td><td width="29%">QTY</td><td width="30%">Shipped</td></tr>'
                        end
                      end

                      content += temp

                      if i==7 
                        content += ' </table></div><article><div class="footer-2"><div class="page"><h3>Page </h3><h4>'+j.to_s+'</h4></div><div class="page-center-2"><h6 id="pk100_so_notes">'+notes+'</h6></div><div class="original"><h3>Customer Copy </h3><h4 id="so_total">$'+so_total+'</h4></div></article></section></div> <div style="page-break-after:always;">&nbsp; </div>'
                      end

                      if len == index+1 && i != 7 
                        # j = 1
                        # j+=1
                        content += '</table></div><article><div class="footer-2"><div class="page"><h3>Page </h3><h4>'+j.to_s+'</h4></div><div class="page-center-2"><h6 id="pk100_so_notes">'+notes+'</h6></div><div class="original"><h3>Customer Copy </h3><h4 id="so_total">$'+so_total+'</h4></div></article>'
                   
                      end 

                      i +=1 

                      if i==8 
                        j+=1
                        i= 1
                        content 
                      end

                 



                    end
                    content

                    so_shipment["part_number"] = content



                    # @so_shipment["alt_part_number"] = item_alt_part

                    SoShipment.complete_shipment(params[:shipment_process_id])
                    result = so_shipment
                  else
                     result = 0
                  end
              else
                result = "fail"
              end  
            when "item_lot_locations"
              if params[:id].present?
                @item = Item.find(params[:id])
                locations = Item.find(params[:id]).quality_lots.order('created_at DESC').map { |x| (x.po_shipment.present? && x.lot_quantity > 0) ? [x.lot_control_no,x.po_shipment.po_shipped_unit.to_s + " - " + x.po_shipment.po_shipped_shelf] : [] } 
                result = locations
              else
                result = "fail"
              end
            when "send_so_order_mail"
              val =  params[:organizations]
              @so_header = SoHeader.find(params[:so_header_id])
              @contact = Contact.find(val["0"]["value"].to_i)
              @customer_email = @contact.contact_email
              if @customer_email.present?
                UserMailer.sales_order_mail(@so_header, @customer_email).deliver
                result = "success"
              else
                result = "fail"
              end 
              
            when "send_invoice"
              @receivable = Receivable.find(params[:receivable_id])
              if @receivable.so_header.present?
                if @receivable.so_header.bill_to_address.present?
                  @customer_eamil = @receivable.so_header.bill_to_address.contact_email
                  UserMailer.customer_billing_mail(@receivable, @customer_eamil).deliver
                end
                result = "success" 
              else
                result = 'fail'
              end
            when "get_item_description"
              if params[:item_id].present?
                description = ItemAltName.find(params[:item_id]).item.current_revision.item_description
                result = description if description
                result = "fail" if !description
              else
                result = "fail"
              end
            when "get_quote_info"
                if params[:quote_id].present?
                  quote = Quote.find(params[:quote_id])
                  result = CustomerQuoteLine.get_line_items(quote)                  
                else
                  result = "fail"
                end
            when "get_item_info"
              if params[:quote_id] && params[:item_id].present?
                result = Quote.get_item_prices(params[:quote_id], params[:item_id])
              else
                result = "fail"
              end
            when "send_customer_quotes_mail"
              if params[:customer_quote_id].present? && params[:contact].present? && params[:organization_id].present?
                organization = Organization.find(params[:organization_id])
                if organization.present?
                  email =(params[:contact] == params[:organization_id]) ? organization.organization_email : organization.contacts.find(params[:contact]).contact_email
                  UserMailer.send_customer_quote(params[:customer_quote_id], email)
                end
                result = "success"
              else
                result = "fail"
              end

            when "set_quote_status"
              if params[:quote_id].present? && params[:status_id].present?
                quote = Quote.find(params[:quote_id])
                quote.quote_status = params[:status_id]
                if quote.save
                  result = "success"
                else
                  result = "fail"
                end
              end
            when "get_vendor_po"
              if params[:organization_id].present? && params[:alt_name_id]
                item_id = ItemAltName.find(params[:alt_name_id]).item.id
                # organization = Organization.find(params[:organization_id])
                result = PoHeader.joins(:po_lines).select("po_headers.po_identifier").where("po_headers.organization_id = ? AND po_lines.item_id = ?", params[:organization_id], item_id).order("po_headers.created_at DESC")
              end
            when "set_customer_quote_status"
              if params[:customer_quote_id].present? && params[:status_id].present?
                  customer_quote = CustomerQuote.find(params[:customer_quote_id])
                  customer_quote.customer_quote_status = params[:status_id]
                  if customer_quote.save
                      result = "success"
                  else
                      result = "fail"
                  end
              end  
            when "process_reconcile"
              if params[:reconcile_ids].present? && params[:balance].present?
                Reconcile.where(id: params[:reconcile_ids]).each do |obj|
                  obj.update_attributes(:tag => "reconciled")
                  if obj.payment_id.present?
                    check_register = CheckRegister.find_by_payment_id(obj.payment_id)
                    check_register.update_attributes(:rec => true) if  check_register
                    credit_register = CreditRegister.find_by_payment_id(obj.payment_id)
                    credit_register.update_attributes(:rec => true) if  credit_register
                  elsif obj.receipt_id.present?
                    check_register = CheckRegister.find_by_receipt_id(obj.receipt_id)
                    check_register.update_attributes(:rec => true) if  check_register                      
                  end  

                end  
                reconciled = Reconciled.first            
                reconciled.update_attributes(balance: params[:balance])
                result ="Success"
              end
             when "add_or_update_expense" 
              if  params[:payable_id].present? && params[:expense_amt].present? 
                payable = Payable.find(params[:payable_id])             
                if payable.update_attributes(:payable_total => params[:expense_amt] )                  
                  result ="Success"
                end
              end 
            when "add_or_update_freight" 
              if  params[:payable_id].present? && params[:freight_amt].present? 
                payable = Payable.find(params[:payable_id])             
                if payable.update_attributes(:payable_freight => params[:freight_amt] )
                  payable.update_payable_total
                  result ="Success"
                end
              end
             when "add_or_update_receivable_freight" 
              if  params[:receivable_id].present? && params[:freight_amt].present? 
                receivable = Receivable.find(params[:receivable_id])             
                if receivable.update_attributes(:receivable_freight => params[:freight_amt] )
                  receivable.update_receivable_total
                  result ="Success"
                end
              end
            when "add_or_update_discount"
              if  params[:payable_id].present? && params[:discount].present? 
                payable = Payable.find(params[:payable_id])             
                if payable.update_attributes(:payable_discount => params[:discount] )
                  payable.update_payable_total
                  result ="Success"
                end
              end
            when "add_or_update_receivable_discount"
              if  params[:receivable_id].present? && params[:discount].present? 
                receivable = Receivable.find(params[:receivable_id])             
                if receivable.update_attributes(:receivable_discount => params[:discount] )
                  receivable.update_receivable_total
                  result ="Success"
                end
              end
            when "set_checklist"
              if params[:id].present? && params[:value].present?
                checklist = CheckListLine.find(params[:id])
                if checklist.update_attributes(:check_list_status => params[:value])
                  result ="Success"
                end
              else
                result = "false"
              end
            when "set_psw_value"              
              if params[:field].present? && params[:psw_id].present? && params[:value].present?         
                Ppap.set_levels(params[:field],params[:psw_id],params[:value], params[:type])                   
                result ="Success"
              else
                result = "fail"
              end
            when "set_tag"
              if params[:id].present? && params[:value].present?
                organization = Organization.find(params[:id])
                tags = params[:value]
                tags = tags.collect(&:strip).compact
                tags = tags.reject(&:empty?)
                Comment.process_comments(current_user, organization, tags, "tag")
                if organization.organization_type.type_value == 'vendor'
                  Commodity.auto_save(tags)
                end
                result ="Success"   
              end
            when "set_process"
              if params[:id].present? && params[:value].present?
                organization = Organization.find(params[:id])
                OrganizationProcess.process_organization_processes(current_user, organization, params[:value])
                result ="Success"   
              end
            when "get_quality_lots"
              if params[:id].present?
                quality_lots = SoLine.find(params[:id]).item.quality_lots.map { |x| (x && x.quantity_on_hand && x.quantity_on_hand > 0) ? [x.id,x.lot_control_no] : [] } 
                result = quality_lots
              end



            when "get_quality_lots_po"
              if params[:id].present?
                quality_lots = PoLine.find(params[:id]).item.quality_lots.map { |x| [x.id,x.lot_control_no] }
                result = quality_lots
              end
            when "get_gl_account_title" 
              gl_account_titles = Hash.new 
              @gl_account = GlAccount.where(:gl_account_identifier =>   "11050").first              
              gl_account_titles["11050"] = @gl_account.gl_account_title
              @gl_account = GlAccount.where(:gl_account_identifier =>   "51010-020").first
              gl_account_titles["51010-020"] = @gl_account["gl_account_title"]
              @gl_account = GlAccount.where(:gl_account_identifier =>   "51020-020").first
              gl_account_titles["51020-020"] = @gl_account["gl_account_title"]
              @gl_account = GlAccount.where(:gl_account_identifier =>   "71107").first
              gl_account_titles["71107"] = @gl_account["gl_account_title"]
              @gl_account = GlAccount.where(:gl_account_identifier =>   "41010-010").first
              gl_account_titles["41010-010"] = @gl_account["gl_account_title"]                       
              @gl_account = GlAccount.where(:gl_account_identifier =>   "51010-010").first
              gl_account_titles["51010-010"] = @gl_account["gl_account_title"]
              @gl_account = GlAccount.where(:gl_account_identifier =>   "41025-010").first
              gl_account_titles["41025-010"] = @gl_account["gl_account_title"]
              
              
              result = gl_account_titles 

            when "after_print_checks"
              if params[:id].present? 
                check_entry = CheckEntry.find(params[:id]) 
                check_entry.update_attributes(:status => "Printed", :check_active => 0)
                payment = Payment.find_by_check_entry_id(params[:id])
                payment.update_transactions
                @reconcile = Reconcile.where(:payment_id => payment.id).first
                if @reconcile.nil?                                  
                  Reconcile.create(tag: "not reconciled",reconcile_type: "check", payment_id: payment.id, printing_screen_id: params[:id])                                             
                end 
                @gl_entries = payment.gl_entries
                if @gl_entries
                  @gl_entries.each do |gl_entry|
                    gl_entry.update_attributes(:gl_entry_description => "Check "+payment.payment_check_code)
                  end
                end
                check_register = CheckRegister.where(payment_id: payment.id).first
                unless  check_register.present?                    
                    balance = 0 
                    amount =  payment.payment_check_amount * -1 
                    gl_account = GlAccount.where('gl_account_identifier' => '11012' ).first                     
                    if  CheckRegister.exists? 
                      check_register = CheckRegister.last                                       
                      balance += amount + check_register.balance
                    else
                      balance += gl_account.gl_account_amount                         
                    end                   
                                                     
                    CheckRegister.create(transaction_date: Date.today.to_s, check_code: payment.payment_check_code, organization_id: payment.organization_id, amount: amount, rec: false, payment_id: payment.id, balance: balance)
                end          
                result = "success"
              end


            when "generate_check_code"                  
              ids = params[:ids]
              res = Hash.new 
              ids.each do |id|
                sleep 1
                c = CheckEntry.find(id)
                check_code = CheckCode.find_by_counter_type('check_code').counter 
                c.update_attributes(:check_code => check_code)
                p = c.payment
                p.update_attributes(:payment_check_code => check_code) if p               
                temp = CheckCode.find_by_counter_type("check_code") 
                temp.update_attributes(:counter => check_code )               
                CheckCode.get_next_check_code                               
                res[id] = check_code
              end 
              result = res

            when "set_lot_numbers"              
              params["ids"].each do |id|
                sleep 1
                if id != "undefined"
                  quality_lot = QualityLot.find(id)
                  if quality_lot.present?
                    if quality_lot.po_line.quality_lot_id.present?
                      transfer_quality = QualityLot.find(quality_lot.po_line.quality_lot_id)
                      control_number = transfer_quality.lot_control_no
                      letter = '@'
                      if QualityLot.where(:lot_control_no => control_number+letter.next).present?
                        begin
                          letter = letter.next!
                          @max_control_string = QualityLot.where(:lot_control_no => control_number+letter)
                        end while(@max_control_string.present?)
                        current_control_no = control_number+letter    
                      else
                        current_control_no = control_number+letter.next
                      end

                      quality_lot.update_column(:lot_control_no, current_control_no)
                    else
                        quality_lot.set_lot_control_no  
                    end
                    
                  end
                end
              end
              result = params["ids"]

            when "get_jr100_print_data"
              @quality_lot = QualityLot.find(params["id"])
              res = Hash.new
              if @quality_lot.present?
                @po_shipment = @quality_lot.po_shipment
                if @po_shipment.present?
                  res["quantity_open"] = @po_shipment.po_line.po_line_quantity - @po_shipment.po_line.po_line_shipped
                  res["shipped_status"] = @po_shipment.po_line.po_line_status   
                  res["part_number"] = @po_shipment.po_line.item.item_part_no
                  res["po"]   = @po_shipment.po_line.po_header.po_identifier
                  res["customer"] = @po_shipment.po_line.organization.organization_name if @po_shipment.po_line.organization                  
                  res["company_name"] =  CompanyInfo.first.company_name
                  res["control_number"] = @quality_lot.lot_control_no
                  result = res
                end
              else                
                result = "Failure"                
              end


            when "after_print_deposits"
              if params[:id].present? 
                deposit_check = DepositCheck.find(params[:id]) 
                deposit_check.update_attributes(:status => "Printed", :active => 0)
                receipt = Receipt.find_by_deposit_check_id(params[:id])
                receipt.update_transactions
                @reconcile = Reconcile.where(:receipt_id => receipt.id).first
                if @reconcile.nil?                                  
                  Reconcile.create(tag: "not reconciled",reconcile_type: "deposit check", receipt_id: receipt.id, deposit_check_id: params[:id])                                             
                end  
                check_register = CheckRegister.where(receipt_id: receipt.id).first
                unless  check_register.present? 
                    if deposit_check.receipt_type != 'credit'
                      balance = 0                  
                      gl_account = GlAccount.where('gl_account_identifier' => '11012' ).first                     
                      if  CheckRegister.exists?                 
                        check_register = CheckRegister.last                          
                        balance +=  receipt.receipt_check_amount + check_register.balance
                      else
                        balance += gl_account.gl_account_amount                           
                      end            

                      CheckRegister.create(transaction_date: Date.today.to_s, check_code: receipt.receipt_check_code, organization_id: receipt.organization_id, deposit: receipt.receipt_check_amount, rec: false, receipt_id: receipt.id, balance: balance)
                    end  
                end          
                result = "success"
              end                    
        end
         render json: {:aaData => result}
    end
end