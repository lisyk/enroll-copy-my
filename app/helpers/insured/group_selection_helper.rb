module Insured
  module GroupSelectionHelper
    def can_shop_individual?(person)
      person.try(:has_active_consumer_role?)
    end

    def can_shop_shop?(person)
      person.try(:has_active_employee_role?)
    end

    def can_shop_both_markets?(person)
      can_shop_individual?(person) && can_shop_shop?(person)
    end

    def health_relationship_benefits(employee_role)
      if employee_role.benefit_group.present?
        employee_role.benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    def dental_relationship_benefits(employee_role)
      if employee_role.benefit_group.present?
        employee_role.benefit_group.dental_relationship_benefits.select(&:offered).map(&:relationship)
      end
    end
  end
end
