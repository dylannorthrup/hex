#!/usr/bin/env ruby
module Hex
  class Card
    @@uuid_to_set = {
      'dacf5a9d-4240-4634-8043-2531365edd83' => 'AI Only Cards',
      '049f321e-3990-45b3-bdc0-5e26d4c33c37' => 'AI_Cards_alternates',
      '24899ce9-4aed-4d26-8b08-3be2894822c5' => 'Campaign Created Champions',
      '08a39fff-3c9f-4658-a6e3-75dfd566abfa' => 'PvE01_AZ_1_NPCs',
      'c363c22e-1c03-43c0-a5d3-e3e8759120e7' => 'PvE_01_Universal_Card_Set',
      '7cef8345-4f5b-407a-a15e-1978ef5ff2db' => 'PvE01_AdventureZone_and_universal_AI_alternates',
      'f982e78b-b008-4789-aa89-9cb24006933f' => 'AZ2 NPCs',
      '1d1ecaea-47c9-4d2a-91a0-9c78fdac49a1' => 'PvE02_Universal_Card_Set',
      '4db9936b-7daf-4ede-ab56-fd9d0c9ec479' => 'PvE02_Universal_Card_Set_alternates',
      'ccde3b6a-3425-4403-b366-dba0e2358fae' => 'PvE_AZ1_Created_Effects',
      '9dac9301-5ca0-4ee0-964a-dfe3dd4fe538' => 'PvE_AZ1_Created_Effects_alternates',
      '50347e9d-d0ca-4645-9f4a-4e6be8e9dbd2' => 'PvE_AZ2_Created_Effects',
      '0382f729-7710-432b-b761-13677982dcd2' => 'Shards of Fate',
      '551349b9-dfd2-4e4d-b173-f53ad8164c18' => 'Set001_alternates',
      '582f8d90-d5e6-41e5-b6f9-5de73de140be' => 'Set01_Kickstarter',
      'e05753ab-ec72-4cbd-a083-d5e54f2907df' => 'Set01_Kickstarter_alternates',
      'd8ee3b8d-d4b7-4997-bbb3-f00658dbf303' => 'Set01_PvE_Arena',
      'a31dd265-9d3b-4ac7-9669-bb1ab19c62bc' => 'Set01_PvE_Arena_alternates',
      '4f38be98-79e3-404c-ab6f-a68e99fede18' => 'Set01_PvE_Holiday',
      'c529ac02-798c-4ccf-b127-afaac107d225' => 'Set01_PvE_Holiday_alternates',
      'cd112780-7766-44e8-bf3b-4cd269d47e3e' => 'Set01_PvE_Talents',
      '794e37a9-442f-4c02-a26a-8120a87e8a6e' => 'Set01_PvE_Talents_alternates',
      '52bc1da1-af3c-4df0-8afb-c999c9f6d645' => 'Set02_PvE_Talents',
      '9eea89ff-a360-4335-a0d8-c08ccce919f5' => 'Set02_PvE_Talents_alternates',
      'b05e69d2-299a-4eed-ac31-3f1b4fa36470' => 'Shattered Destiny',
      '8e8d7225-ab32-4cf7-abbc-d4d4178fa022' => 'Set02_PvP_alternates',
      '3cc27cc9-b3af-44c7-a5de-4126f78d96ed' => 'Set03_PvE_Promo',
      '99637584-687d-498c-9eaf-375480972543' => 'Set03_PvE_Promo_alternates',
      'fce480eb-15f9-4096-8d12-6beee9118652' => 'Armies of Myth',
      '0c1bf67d-70ac-4b2a-b57b-696567c90d50' => 'Set03_PvP_alternates',
      'e3217d24-bff4-4159-94bc-4653012a14cd' => 'Set04_PvE_Promo',
      '7257041a-5c83-452f-8b03-b03478307a00' => 'Set04_PvE_Promo_alternates',
      '2d05262c-d7a0-408f-a280-36d206a29344' => 'Primal Dawn',
      'a2379dcc-5da0-4444-92bc-cac425d5f712' => 'Set04_PvP_alternates',
    }
    @@uuid_to_set.default = 'None_Defined'
  end
end
