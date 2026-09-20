export const propertyTypes = [
  {
    value: 'land',
    label: 'Land',
  },
  {
    value: 'flat',
    label: 'Flat',
  },
  {
    value: 'house',
    label: 'House',
  },
  {
    value: 'inherited-property',
    label: 'Inherited Property',
  },
  {
    value: 'commercial-property',
    label: 'Commercial Property',
  },
  {
    value: 'other',
    label: 'Other',
  },
];

export const decisionIntents = [
  {
    value: 'buy',
    label: 'জমি কিনতে চাই',
  },
  {
    value: 'sell',
    label: 'জমি বিক্রি করতে চাই',
  },
  {
    value: 'inherited',
    label: 'উত্তরাধিকারসূত্রে property পেয়েছি',
  },
  {
    value: 'verify',
    label: 'নিজের property যাচাই করতে চাই',
  },
  {
    value: 'dispute',
    label: 'Property dispute আছে',
  },
  {
    value: 'information',
    label: 'শুধু information জানতে চাই',
  },
];

export const questions = [
  {
    id: 'ownershipDocuments',
    label: 'মালিকানার documents কি যাচাই করা হয়েছে?',
    shortLabel: 'Ownership Documents',
    type: 'verification',
  },

  {
    id: 'ownershipChain',
    label: 'Ownership Chain কি জানা আছে?',
    shortLabel: 'Ownership Chain',
    type: 'verification',
  },

  {
    id: 'khatian',
    label: 'Relevant Khatian কি যাচাই করা হয়েছে?',
    shortLabel: 'Khatian',
    type: 'verification',
  },

  {
    id: 'landRecords',
    label: 'Land record information কি যাচাই করা হয়েছে?',
    shortLabel: 'Land Records',
    type: 'verification',
  },

  {
    id: 'knownDispute',
    label: 'Property নিয়ে কোনো known dispute আছে কি?',
    shortLabel: 'Known Dispute',
    type: 'dispute',
  },

  {
    id: 'inheritance',
    label: 'এই property-তে inheritance জড়িত কি?',
    shortLabel: 'Inheritance',
    type: 'context',
  },
];

export const answers = [
  {
    value: 'yes',
    label: 'হ্যাঁ',
  },
  {
    value: 'no',
    label: 'না',
  },
  {
    value: 'not-sure',
    label: 'নিশ্চিত নই',
  },
];