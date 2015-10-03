class VlpDocument < Document

  NATURALIZATION_DOCUMENT_TYPES = ["Certificate of Citizenship", "Naturalization Certificate"]

  VLP_DOCUMENT_IDENTIFICATION_KINDS = [
      "Alien Number",
      "I-94 Number",
      "Visa Number",
      "Passport Number",
      "SEVIS ID",
      "Naturalization Number",
      "Receipt Number",
      "Citizenship Number",
      "Card Number"
    ]

  VLP_DOCUMENT_KINDS = [
      "I-327 (Reentry Permit)",
      "I-551 (Permanent Resident Card)",
      "I-571 (Refugee Travel Document)",
      "I-766 (Employment Authorization Card)",
      "Certificate of Citizenship",
      "Naturalization Certificate",
      "Machine Readable Immigrant Visa (with Temporary I-551 Language)",
      "Temporary I-551 Stamp (on passport or I-94)",
      "I-94 (Arrival/Departure Record)",
      "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport",
      "Unexpired Foreign Passport",
      "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)",
      "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)",
      "Other (With Alien Number)",
      "Other (With I-94 Number)"
    ]

  field :alien_number, type: String
  field :i94_number, type: String
  field :visa_number, type: String
  field :passport_number, type: String
  field :sevis_id, type: String
  field :naturalization_number, type: String
  field :receipt_number, type: String
  field :citizenship_number, type: String
  field :card_number, type: String

  # date of expiration of the document. e.g. passport / documentexpiration date
  field :expiration_date, type: Date

  # country which issued the document. e.g. passport issuing country
  field :issuing_country, type: String

  validates :subject,
        inclusion: { in: VLP_DOCUMENT_KINDS, message: "%{value} is not a valid subject" },
        allow_blank: false

  validates :alien_number, length: { is: 9 }, :allow_blank => true
  validates :citizenship_number, length: { within: 7..9 }, :allow_blank => true
  validates :i94_number, length: { is: 11 }, :allow_blank => true
  validates :naturalization_number, length: { within: 7..12 }, :allow_blank => true
  validates :passport_number, length: { within: 6..12 }, :allow_blank => true
  validates :sevis_id, length: { is: 11 } , :allow_blank => true #first char is N
  validates :visa_number, length: { is: 8 }, :allow_blank => true
  validates :receipt_number, length: { is: 13}, :allow_blank => true #first 3 alpha, remaining 10 string


  validate :document_required_fields

  # hash of doc type and necessary fields
  def required_fields
    {
        "I-327 (Reentry Permit)":[:alien_number],
        "I-551 (Permanent Resident Card)": [:alien_number, :card_number],
        "I-571 (Refugee Travel Document)": [:alien_number],
        "I-766 (Employment Authorization Card)": [:alien_number, :card_number],
        "Certificate of Citizenship": [:alien_number, :citizenship_number],
        "Naturalization Certificate": [:alien_number, :naturalization_number],
        "Machine Readable Immigrant Visa (with Temporary I-551 Language)": [:alien_number, :passport_number],
        "Temporary I-551 Stamp (on passport or I-94)": [:alien_number],
        "I-94 (Arrival/Departure Record)": [:i94_number],
        "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport": [:i94_number, :passport_number],
        "Unexpired Foreign Passport": [:passport_number],
        "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)": [:sevis_id],
        "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)": [:sevis_id],
        "Other (With Alien Number)": [:alien_number, :description],
        "Other (With I-94 Number)": [:i94_number,:description]
    }
  end

  private
  def document_required_fields
     required_fields[self.subject.to_sym].each do |field|
       errors.add(:base, "#{field} value is required") unless self.send(field).present?
     end
  end


end