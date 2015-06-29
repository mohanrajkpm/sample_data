class Item < ActiveRecord::Base
  attr_accessible :item_part_no, :item_quantity_in_hand, :item_quantity_on_order, :item_active,
  :item_created_id, :item_updated_id, :item_revisions_attributes, :item_alt_part_no

  has_many :item_revisions, :dependent => :destroy
  has_many :quote_lines, :dependent => :destroy
  has_many :quotes , :through => :quote_lines
  has_many :customer_quote_lines, :dependent => :destroy
  has_many :customer_quotes, :through => :customer_quote_lines

  has_many :item_part_dimensions, :through => :item_revisions

  has_many :po_lines, :dependent => :destroy
  has_many :po_shipments, :through => :po_lines
  has_many :quality_lots, :through => :po_lines

  has_many :so_lines, :dependent => :destroy
  has_many :so_shipments, :through => :so_lines

  has_many :item_alt_names, :dependent => :destroy
  has_many :quality_actions, :dependent => :destroy

  has_many :inventory_adjustments, :dependent => :destroy

  has_many :item_lots
  
  accepts_nested_attributes_for :item_revisions, :allow_destroy => true

  after_initialize :default_values

  def default_values
    self.item_active = true if self.attributes.has_key?("item_active") && self.item_active.nil?
  end

  after_create :create_alt_name

  def create_alt_name
      self.item_alt_names.new(:item_alt_identifier => self.item_part_no).save(:validate => false)

      quotes_lines = QuoteLine.where("item_name_sub = ?",self.item_part_no)
      customer_quote_lines = CustomerQuoteLine.where("item_name_sub = ?", self.item_part_no)
      item_alt_name = ItemAltName.find_by_item_alt_identifier(self.item_part_no)
      quotes_lines.each do |quote_line|
        quote_line.item_id = self.id
        quote_line.item_revision_id = self.current_revision.id
        quote_line.item_alt_name_id = item_alt_name.id
        quote_line.item_name_sub = ""
        quote_line.save(:validate => false)
      end

      customer_quote_lines.each do |customer_quote_line|
        customer_quote_line.item_id = self.id
        customer_quote_line.item_revision_id = self.current_revision.id
        customer_quote_line.item_alt_name_id = item_alt_name.id
        customer_quote_line.item_name_sub = ""
        customer_quote_line.save(:validate => false)
      end
      unless self.item_alt_part_no == ""
        self.item_alt_names.new(:item_alt_identifier => self.item_alt_part_no).save(:validate => false)  
      end
      
  end

  after_update :update_alt_name

  def update_alt_name
      alt_names = self.item_alt_names.where("organization_id is NULL")
      alt_names.each do |alt_name|
          alt_name.item_alt_identifier = self.item_part_no
          alt_name.save(:validate => false)
      end
  end
  
  (validates_uniqueness_of :item_part_no if validates_length_of :item_part_no, :minimum => 2, :maximum => 50) if validates_presence_of :item_part_no
   
  def current_revision
      # self.item_revisions.find_by_latest_revision(true)
      self.item_revisions.order("item_revision_date desc").first
  end

  scope :item_with_recent_revisions, joins(:item_revisions).where("item_revisions.latest_revision = ?", true)

  def customer_alt_names
      alt_names = []
      self.item_alt_names.each do |alt_name|
        if alt_name.item_alt_identifier != self.item_part_no
          alt_names << alt_name
        end
      end
      alt_names
  end

  def purchase_orders
      PoHeader.joins(:po_lines).where("po_lines.item_id = ?", self.id).order('created_at desc')
  end

  def sales_orders
      SoHeader.joins(:so_lines).where("so_lines.item_id = ?", self.id).order('created_at desc')
  end 

  def qty_on_order
    # self.po_lines.sum(:po_line_quantity)
    # self.last.po_lines.joins(:po_header).where(po_headers: {po_status: "open"}).sum(:po_line_quantity)
    self.po_lines.where(:po_line_status => "open").includes(:po_header).where(po_headers: {po_status: "open"}).sum("po_line_quantity - po_line_shipped")

  end

  def qty_on_committed
   self.so_lines.where(:so_line_status => "open").includes(:so_header).where(so_headers: {so_status: "open"}).sum("so_line_quantity - so_line_shipped")
  end

  def qty_on_hand
      self.quality_lots.sum(:quantity_on_hand).to_f
  end
  def weighted_cost
    total = qty_on_hand
    cost =0
    if total == 0
      cost
    else
      self.quality_lots.each do |quality_lot|
        cost += (quality_lot.quantity_on_hand.to_f/total)*quality_lot.po_line.po_line_cost.to_f
      end
      cost.round(5)
    end
  end



  def current_location
      po_shipment = self.po_shipments.order(:created_at).last
      po_shipment.nil? ? "-" : po_shipment.po_shipped_unit.to_s + " - " + po_shipment.po_shipped_shelf
  end
  
end
