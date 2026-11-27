BEGIN;
-- Internal stable codes, not ISO codes. Sorani strings require native review.
INSERT INTO logistics.governorate(code,name_en,name_ar,name_ku,source_url) VALUES
('BAG','Baghdad','بغداد','بەغدا','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('BAS','Basra','البصرة','بەسرە','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('ERB','Erbil','أربيل','هەولێر','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('SUL','Sulaymaniyah','السليمانية','سلێمانی','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('DUH','Duhok','دهوك','دهۆک','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('HAL','Halabja','حلبجة','هەڵەبجە','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('NIN','Nineveh','نينوى','نەینەوا','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('KIR','Kirkuk','كركوك','کەرکووک','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('ANB','Anbar','الأنبار','ئەنبار','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('DIY','Diyala','ديالى','دیالە','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('SAL','Salah al-Din','صلاح الدين','سەلاحەدین','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('KAR','Karbala','كربلاء','کەربەلا','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('NAJ','Najaf','النجف','نەجەف','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('BAB','Babil','بابل','بابل','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('WAS','Wasit','واسط','واسیت','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('DHI','Dhi Qar','ذي قار','زیقار','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('MAY','Maysan','ميسان','مەیسان','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('MUT','Muthanna','المثنى','موسەننا','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf'),
('QAD','Al-Qadisiyah','القادسية','قادسیە','https://assets.publishing.service.gov.uk/media/6144b2cde90e07043e85e0c5/Iraq-PCGN_Toponymic_Factfile-2021-final_version.pdf');
INSERT INTO payments.provider(code,capabilities) VALUES
('ZAINCASH','{}'::jsonb),
('FASTPAY','{}'::jsonb),
('FIB','{}'::jsonb),
('ASIAPAY','{}'::jsonb),
('QI_CARD','{}'::jsonb),
('NASSWALLET','{}'::jsonb),
('AGGREGATOR','{}'::jsonb);
COMMIT;
