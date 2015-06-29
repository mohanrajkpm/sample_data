class MasterType < ActiveRecord::Base
  attr_accessible :type_active, :type_category, :type_description, :type_name, :type_value, :quality_document_id
  belongs_to :quality_document
  scope :po_types, where(:type_category => 'po_type')

  scope :organization_types, where(:type_category => 'organization_type')

  scope :quality_levels, where(:type_category => 'customer_quality_level')

  scope :payment_types, where(:type_category => 'payment_type')

  scope :gl_modes, where(:type_category => 'gl_mode')

  scope :gl_categories, where(:type_category => 'gl_category')  

  scope :ic_actions, where(:type_category => 'icp_quallity_action')

  scope :organization_quality_types, where(:type_category => 'organization_type_q_a')

  scope :customer_feedback_types, where(:type_category => 'customer_response')

  has_many :owners, :class_name => "Owner", :foreign_key => "owner_commission_type_id"

  has_many :type_based_organizations, :class_name => "Organization", :foreign_key => "organization_type_id"

  has_many :contact_based_organizations, :class_name => "Organization", :foreign_key => "customer_contact_type_id"

  has_many :type_based_pos, :class_name => "PoHeader", :foreign_key => "po_type_id"

  has_many :level_based_lots, :class_name => "QualityLot", :foreign_key => "inspection_level_id"
  has_many :method_based_lots, :class_name => "QualityLot", :foreign_key => "inspection_method_id"
  has_many :type_based_lots, :class_name => "QualityLot", :foreign_key => "inspection_type_id"

  has_many :type_based_payments, :class_name => "Payment", :foreign_key => "payment_type_id"

  has_many :type_based_gl_accounts, :class_name => "GlAccount", :foreign_key => "gl_type_id"

  has_many :type_based_quality_actions, :class_name => "QualityAction", :foreign_key=> "ic_action_id"

  has_many :feedback_types, :class_name => "CustomerFeedback", :foreign_key => "customer_feedback_type_id"

  has_many :type_based_organization_quality_type, :class_name => "QualityAction", :foreign_key => "organization_quality_type_id"

  has_many :customer_quality_levels, :dependent => :destroy

  has_many :check_list_line, :dependent => :destroy

  has_many :customer_qualities, :through => :customer_quality_levels

  validates_uniqueness_of :type_value

  # owner / commission_type -> Sell * quantityshipped, [sell-cost]*quantityshipped
  # customer quality level / forms -> 
  # organization -> type - customer, vendor, support
  # po -> type - 

  # before_save :process_before_save
  # def process_before_save
  #     self.type_value = self.type_name.urlize
  # end

end
