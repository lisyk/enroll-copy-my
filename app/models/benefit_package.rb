class BenefitPackage
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :benefit_coverage_period

  ELIGIBLE_RELATIONSHIP_CATEGORY_KINDS = %w(
      self
      spouse
      domestic_partner
      children_under_26
      disabled_children_26_and_over
      children_26_and_over
      dependents
    )

  BENEFIT_BEGIN_OFFSET_PERIOD_KINDS = [0, 30, 60, 90]
  BENEFIT_EFFECTIVE_DATE_KINDS      = %w(date_of_event first_of_month)
  BENEFIT_TERMINATION_DATE_KINDS    = %w(date_of_event end_of_month)

  # Premium Credit Strategies
  # 1. Unassisted: subscriber is responsible for total premium cost
  # 2. Lump sum contribution: fixed dollar amount applied toward subscriber's total premium cost
  # 3. Allocated lump sum credit (e.g. APTC): fixed dollar amount apportioned among eligible relationship categories
  # 4. Percentage contribution: contribution ratio applied to each eligible relationship category 
  # 5. Indexed percentage contribution (e.g. DCHL SHOP method): using selected reference benefit, contribution ratio applied to each eligible relationship category 
  # 6. (congress)
  PREMIUM_CREDIT_STRATEGY_KINDS  = %w(unassisted lump_sum_contribution allocated_lump_sum_credit percentage_contribution indexed_percentage_contribution)

  field :title, type: String, default: ""

  field :eligible_relationship_categories, type: Array, default: []
  field :benefit_begin_offset_periods, type: Array, default: []
  field :benefit_effective_dates, type: Array, default: []
  field :benefit_termination_dates, type: Array, default: []

  field :elected_premium_credit_strategy, type: String
  field :index_benefit_id, type: BSON::ObjectId
  field :benefit_ids, type: Array, default: []

  delegate :start_on, :end_on, to: :benefit_coverage_period

  embeds_one :premium_credit_strategy

  # validates :eligible_relationship_categories,
  #   allow_blank: false,
  #   inclusion: {
  #     in: ELIGIBLE_RELATIONSHIP_CATEGORY_KINDS,
  #     message: "%{value} is not a valid eligble relationship category kind"
  #   }

  # validates :benefit_begin_offset_periods,
  #   allow_blank: false,
  #   inclusion: {
  #     in: BENEFIT_BEGIN_OFFSET_PERIOD_KINDS,
  #     message: "%{value} is not a valid benefit begin offset period kind"
  #   }

  # validates :benefit_effective_dates,
  #   allow_blank: false,
  #   inclusion: {
  #     in: BENEFIT_EFFECTIVE_DATE_KINDS,
  #     message: "%{value} is not a valid benefit effective date kind"
  #   }

  # validates :benefit_termination_dates,
  #   allow_blank: false,
  #   inclusion: {
  #     in: BENEFIT_TERMINATION_DATE_KINDS,
  #     message: "%{value} is not a valid benefit termination date kind"
  #   }

  validates :elected_premium_credit_strategy,
    allow_blank: false,
    inclusion: {
      in: PREMIUM_CREDIT_STRATEGY_KINDS,
      message: "%{value} is not a valid premium credit strategy kind"
    }

end