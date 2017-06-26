class Databases < ActiveRecord::Base
  require 'dotenv'
   # HTTPI::Response::SuccessfulResponseCodes = HTTPI::Response::SuccessfulResponseCodes.to_a << 302
    HTTPI.adapter = :net_http
  conf = YAML.load(ERB.new(File.read("#{Rails.root}/config/database.yml")).result)
  ActiveRecord::Base.establish_connection(
  conf[Rails.env]
  )
  def self.update
    Rails.logger.info("Successfully entered Databases.update #{Time.now}")
    wsdl_path = 'https://rmws.serialssolutions.com/serialssolutionswebservice/SerialsSolutions360WebService.asmx?wsdl'
    client = Savon.client(
       :read_timeout => 180,
       :wsdl => wsdl_path,
       :ssl_verify_mode => :none,
       :raise_errors => true,
       :convert_request_keys_to => :none,
      # :log => true,
      # :log_level => :debug,
       :follow_redirects => true,
       :unwrap => true,
       :pretty_print_xml => true
       ) #do convert_request_keys_to :none end
    #Rails.logger.info("Client = #{client}")
    
    response2 = client.call(:license_data, message: { :request => { :LibraryCode => ENV['ERM_LIBCODE'], :UserName => ENV['ERM_USERNAME'], :Password => ENV['ERM_PASSWORD']}})
    if response2.nil? or response2.blank?
       Rails.logger.info("Response is nil or blank")
    else
       Rails.logger.info("Response has content")
       ::Erm_data.delete_all
    response = response2.to_s
    response = response.gsub!('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><LicenseDataResponse xmlns="http://serialssolutions.com/">','')
    response = response.gsub!('</LicenseDataResponse>','')
    response = response.gsub!('</soap:Body>','')
    response = response.gsub!('</soap:Envelope>','')
    xml_data = Nokogiri::XML(response)
#    File.open('somewhere.xml', 'w') { |file| file.write(xml_data) }
#    output = File.open('todays.sql', 'w+')
#    xml_data = Nokogiri::XML(File.open('somewhere.xml','r'))
    @licenses = xml_data.xpath(sprintf('//%s','License'))
    licenseCount = 1
    xml_data.xpath(sprintf('.//%s',"License")).each do |k|
       licenseName = k.xpath(sprintf('./%s', "LicenseName/Content")).inner_text
       licenseId = k.xpath(sprintf('./%s', "LicenseId/Content")).inner_text
       type = k.xpath(sprintf('./%s', "Type/Content")).inner_text
       vendorLicenseURL = k.xpath(sprintf('./%s', "VendorLicenseURL/Content")).inner_text
       vendorLicenseURLVisibleInPublicDisplay = k.xpath(sprintf('./%s', "VendorLicenseURLVisibleInPublicDisplay/Content")).inner_text
       vendorLicenseURLDateAccessed = k.xpath(sprintf('./%s', "VendorLicenseURLDateAccesed/Content")).inner_text
       if vendorLicenseURLDateAccessed == ''
         vendorLicenseURLDateAccessed = '0000-00-00'
       end
       secondVendorLicenseURL = k.xpath(sprintf('./%s', "SecondVendorLicenseURL/Content")).inner_text
       localLicenseURL = k.xpath(sprintf('./%s', "localLicenseURL/Content")).inner_text
       localLicenseURLVisibleInPublicDisplay = k.xpath(sprintf('./%s', "LocalLicenseURLVisibleInPublicDisplay/Content")).inner_text
       secondLocalLicenseURL = k.xpath(sprintf('./%s', "SecondLocalLicenseURL/Content")).inner_text
       physicalLocation = k.xpath(sprintf('./%s', "PhysicalLocation/Content")).inner_text
       status = k.xpath(sprintf('./%s', "Status/Content")).inner_text
       reviewer = k.xpath(sprintf('./%s', "Reviewer/Content")).inner_text
       reviewerNote = k.xpath(sprintf('./%s', "ReviewerNote/Content")).inner_text
       licenseReplacedBy = k.xpath(sprintf('./%s', "LicenseReplacedBy/Content")).inner_text
       licenseReplaces = k.xpath(sprintf('./%s', "LicenseReplaces/Content")).inner_text
       executionDate = k.xpath(sprintf('./%s', "ExecutionDate/Content")).inner_text
       if executionDate == ''
         executionDate = '0000-00-00'
       end
       startDate = k.xpath(sprintf('./%s', "StartDate/Content")).inner_text
       if startDate == ''
         startDate = '0000-00-00'
       end
       endDate = k.xpath(sprintf('./%s', "EndDate/Content")).inner_text
       if endDate == ''
         endDate = '0000-00-00'
       end
       advanceNoticeInDays = k.xpath(sprintf('./%s', "AdvanceNoticeInDays/Content")).inner_text
       licenseNote = ""
       licenseNote = k.xpath(sprintf('./%s', "LicenseNote/Content")).inner_text
       if licenseNote.nil? or licenseNote.blank?
         licenseNote = ""
       end
       if !licenseNote.blank?
          licenseNote.gsub!('"',' ')
          licenseNote.gsub!("'"," ")
       end
       templateNote = k.xpath(sprintf('./%s', "TemplateNote/Content")).inner_text
       dateCreated = k.xpath(sprintf('./%s', "DateCreated/Content")).inner_text
       if dateCreated == ''
         dateCreated = '0000-00-00'
       end
       lastUpdated = k.xpath(sprintf('./%s', "LastUpdated/Content")).inner_text
       if lastUpdated == ''
         lastUpdated = '0000-00-00'
       end
       licenseTerms = k.xpath(sprintf('./%s', "LicenseTerms"))
       resources = k.xpath(sprintf('./%s', "LicenseResources/Resource"))
       authorizedUsers = licenseTerms.xpath("AuthorizedUsers")
       authUsers = []
       authUsersString = ""
          authorizedUsers.xpath("Content/string").each do |users|
              punks = users.inner_text
              authUsers << punks
          end
       authorizedUsers = authUsers.join("| ")
       authorizedUsersNote = licenseTerms.xpath(sprintf('./%s', "AuthorizedUsersNote/Content")).inner_text
       concurrentUsers = licenseTerms.xpath(sprintf('./%s', "ConcurrentUsers/Content")).inner_text
       concurrentUsers.gsub!('"','')
       concurrentUsersNote = licenseTerms.xpath(sprintf('./%s', "ConcurrentUsersNote/Content")).inner_text
       concurrentUsersNote.gsub!('"','')
       fairUseClauseIndicator = licenseTerms.xpath(sprintf('./%s', "FairUseClauseIndicator/Content")).inner_text
       databaseProtectionOverrideClauseIndicator = licenseTerms.xpath(sprintf('./%s', "DatabaseProtectionOverrideClauseIndicator/Content")).inner_text
       allRightsReservedIndicator = licenseTerms.xpath(sprintf('./%s', "AllRightsReservedIndicator/Content")).inner_text
       citationRequirementDetail = licenseTerms.xpath(sprintf('./%s', "CitationRequirementDetail/Content")).inner_text
       digitallyCopy = licenseTerms.xpath(sprintf('./%s', "DigitallyCopy/Content")).inner_text
       digitallyCopyNote = licenseTerms.xpath(sprintf('./%s', "DigitallyCopyNote/Content")).inner_text
       printCopy = licenseTerms.xpath(sprintf('./%s', "PrintCopy/Content")).inner_text
       printCopyNote = licenseTerms.xpath(sprintf('./%s', "PrintCopyNote/Content")).inner_text
       scholarlySharing = licenseTerms.xpath(sprintf('./%s', "ScholarlySharing/Content")).inner_text
       scholarlySharingNote = licenseTerms.xpath(sprintf('./%s', "ScholarlySharingNote/Content")).inner_text.gsub!('"','')
       if scholarlySharingNote.nil?
         scholarlySharingNote = ""
       end
       distanceLearning = licenseTerms.xpath(sprintf('./%s', "DistanceLearning/Content")).inner_text
       distanceLearningNote = licenseTerms.xpath(sprintf('./%s', "DistanceLearningNote/Content")).inner_text
       iLLGeneral = licenseTerms.xpath(sprintf('./%s', "ILLGeneral/Content")).inner_text
       iLLSecureElectronic = licenseTerms.xpath(sprintf('./%s', "ILLSecureElectronic/Content")).inner_text
       iLLElectronicEmail = licenseTerms.xpath(sprintf('./%s', "ILLElectronicEmail/Content")).inner_text
       iLLRecordKeeping = licenseTerms.xpath(sprintf('./%s', "ILLRecordKeeping/Content")).inner_text
       if iLLRecordKeeping.nil? or iLLRecordKeeping.blank?
         iLLRecordKeeping = ""
       end
       if !iLLRecordKeeping.blank?
          iLLRecordKeeping.gsub!('"',' ')
          iLLRecordKeeping.gsub!("'",' ')
       end
       iLLRecordKeepingNote = licenseTerms.xpath(sprintf('./%s', "ILLRecordKeepingNote/Content")).inner_text
       if iLLRecordKeepingNote.nil? or iLLRecordKeepingNote.blank?
         iLLRecordKeepingNote = ""
       end
       if !iLLRecordKeepingNote.blank?
          iLLRecordKeepingNote.gsub!('"',' ')
          iLLRecordKeepingNote.gsub!("'"," ")
       end
       courseReserve = licenseTerms.xpath(sprintf('./%s', "CourseReserveContent")).inner_text
       if courseReserve.nil? or courseReserve.blank?
         courseReserve = ""
       end
       if !courseReserve.blank?
          courseReserve.gsub!('"',' ')
          courseReserve.gsub!("'",' ')
       end
       courseReserveNote = licenseTerms.xpath(sprintf('./%s', "CourseReserveNote/Content")).inner_text
       if courseReserveNote.nil? or courseReserveNote.blank?
         courseReserveNote = ""
       end
       if !courseReserveNote.blank?
          courseReserveNote.gsub!('"',' ')
          courseReserveNote.gsub!("'",' ')
       end
       electronicLink = licenseTerms.xpath(sprintf('./%s', "ElectronicLink/Content")).inner_text
       electronicLinkNote = licenseTerms.xpath(sprintf('./%s', "ElectronicLinkNote/Content")).inner_text
       if !electronicLinkNote.blank?
          electronicLinkNote.gsub!('"',' ')
          electronicLinkNote.gsub!("'"," ")
       end
       coursePackPrint = licenseTerms.xpath(sprintf('./%s', "CoursePackPrint/Content")).inner_text
       coursePackElectronic = licenseTerms.xpath(sprintf('./%s', "CoursePackElectronic/Content")).inner_text
       coursePackNote = licenseTerms.xpath(sprintf('./%s', "CoursePackNote/Content")).inner_text
       if !coursePackNote.blank?
          coursePackNote.gsub!('"','\"')
          coursePackNote.gsub!("'"," ")
       end
       remoteAccess = licenseTerms.xpath(sprintf('./%s', "RemoteAccess/Content")).inner_text
       remoteAccessNote = licenseTerms.xpath(sprintf('./%s', "RemoteAccessNote/Content")).inner_text
       remoteAccessNote = licenseTerms.xpath(sprintf('./%s', "CoursePackNote/Content")).inner_text
       if !remoteAccessNote.blank?
          remoteAccessNote.gsub!('"',' ')
          remoteAccessNote.gsub!("'"," ")
       end
       otherUseRestrictionsStaffNote = licenseTerms.xpath(sprintf('./%s', "OtherUseRestrictionsStaffNote/Content")).inner_text.gsub!('"','')
       if otherUseRestrictionsStaffNote.nil?
         otherUseRestrictionsStaffNote = ''
       end
      # otherUseRestrictionsStaffNote = otherUseRestrictionsStaffNote.gsub!('\\\"','')
       otherUseRestrictionsPublicNote = licenseTerms.xpath(sprintf('./%s', "OtherUseRestrictionsPublicNote/Content")).inner_text
       perpetualAccessRight = licenseTerms.xpath(sprintf('./%s', "PerpetualAccessRight/Content")).inner_text
       perpetualAccessHoldings = licenseTerms.xpath(sprintf('./%s', "PerpetualAccessHoldings/Content")).inner_text
       perpetualAccessNote = licenseTerms.xpath(sprintf('./%s', "PerpetualAccessNote/Content")).inner_text.gsub('"','\\"')
       perpetualAccessNote = licenseTerms.xpath(sprintf('./%s', "PerpetualAccessNote/Content")).inner_text.gsub('"','\\"')
       licenseeTerminationRight = licenseTerms.xpath(sprintf('./%s', "LicenseeTerminationRight/Content")).inner_text
       licenseeTerminationCondition = licenseTerms.xpath(sprintf('./%s', "LicenseeTerminationCondition/Content")).inner_text
       licenseeTerminationNote = licenseTerms.xpath(sprintf('./%s', "LicenseeTerminationNote/Content")).inner_text
       licenseeNoticePeriodForTerminationNumber = licenseTerms.xpath(sprintf('./%s', "LicenseeNoticePeriodForTerminationNumber/Content")).inner_text
       licenseeNoticePeriodForTerminationUnit = licenseTerms.xpath(sprintf('./%s', "LicenseeNoticePeriodForTerminationUnit/Content")).inner_text
       licensorTerminationRight = licenseTerms.xpath(sprintf('./%s', "LicensorTerminationRight/Content")).inner_text
       licensorTerminationCondition = licenseTerms.xpath(sprintf('./%s', "LicensorTerminationCondition/Content")).inner_text
       licensorTerminationNote = licenseTerms.xpath(sprintf('./%s', "LicensorTerminationNote/Content")).inner_text
       licensorTerminationNote = licensorTerminationNote.gsub('"','')
       licensorNoticePeriodForTerminationNumber = licenseTerms.xpath(sprintf('./%s', "LicensorNoticePeriodForTerminationNumber/Content")).inner_text
       licensorNoticePeriodForTerminationUnit = licenseTerms.xpath(sprintf('./%s', "LicensorNoticePeriodForTerminationUnit/Content")).inner_text
       terminationRightNote = licenseTerms.xpath(sprintf('./%s', "TerminationRightNote/Content")).inner_text
       terminationRequirements = licenseTerms.xpath(sprintf('./%s', "TerminationRequirements/Content")).inner_text
       termsNote = licenseTerms.xpath(sprintf('./%s', "TermsNote/Content")).inner_text
       localUseTermsNote = licenseTerms.xpath(sprintf('./%s', "LocalUseTermsNote/Content")).inner_text
       governingLaw = licenseTerms.xpath(sprintf('./%s', "GoverningLaw/Content")).inner_text
       governingJurisdiction = licenseTerms.xpath(sprintf('./%s', "GoverningJurisdiction/Content")).inner_text
       governingJurisdiction = governingJurisdiction.gsub('"','')
       applicableCopyrightLaw = licenseTerms.xpath(sprintf('./%s', "ApplicableCopyrightLaw/Content")).inner_text
       curePeriodForBreachNumber = licenseTerms.xpath(sprintf('./%s', "CurePeriodForBreachNumber/Content")).inner_text
       curePeriodForBreachUnit = licenseTerms.xpath(sprintf('./%s', "CurePeriodForBreachUnit/Content")).inner_text
       renewalType = licenseTerms.xpath(sprintf('./%s', "RenewalType/Content")).inner_text
       nonRenewalNoticePeriodNumber = licenseTerms.xpath(sprintf('./%s', "NonRenewalNoticePeriodNumber/Content")).inner_text
       nonRenewalNoticePeriodUnit = licenseTerms.xpath(sprintf('./%s', "NonRenewalNoticePeriodUnit/Content")).inner_text
       archivingRight = licenseTerms.xpath(sprintf('./%s', "ArchivingRight/Content")).inner_text
       archivingFormat = licenseTerms.xpath(sprintf('./%s', "ArchivingFormat/Content")).inner_text
       archivingNote = licenseTerms.xpath(sprintf('./%s', "ArchivingNote/Content")).inner_text
       prePrintArchiveAllowed = licenseTerms.xpath(sprintf('./%s', "PrePrintArchiveAllowed/Content")).inner_text
       prePrintArchiveConditions = licenseTerms.xpath(sprintf('./%s', "PrePrintArchiveConditions/Content")).inner_text
       prePrintArchiveRestrictionsNumber = licenseTerms.xpath(sprintf('./%s', "PrePrintArchiveRestrictionsNumber/Content")).inner_text
       prePrintArchiveRestrictionsUnit = licenseTerms.xpath(sprintf('./%s', "PrePrintArchiveRestrictionsUnit/Content")).inner_text
       prePrintArchiveNote = licenseTerms.xpath(sprintf('./%s', "PrePrintArchiveNote/Content")).inner_text
       postPrintArchiveAllowed = licenseTerms.xpath(sprintf('./%s', "PostPrintArchiveAllowed/Content")).inner_text
       postPrintArchiveRestrictionsNumber = licenseTerms.xpath(sprintf('./%s', "PostPrintArchiveRestrictionsNumber/Content")).inner_text
       postPrintArchiveRestrictionsUnit = licenseTerms.xpath(sprintf('./%s', "PostPrintArchiveRestrictionsUnit/Content")).inner_text
       postPrintArchiveNote = licenseTerms.xpath(sprintf('./%s', "PostPrintArchiveNote/Content")).inner_text
       incorporationOfImagesFiguresAndTablesRight = licenseTerms.xpath(sprintf('./%s', "IncorporationOfImagesFiguresAndTablesRight/Content")).inner_text
       incorporationOfImagesFiguresAndTablesNote = licenseTerms.xpath(sprintf('./%s', "IncorporationOfImagesFiguresAndTablesNote/Content")).inner_text.gsub!('"','')
       if incorporationOfImagesFiguresAndTablesNote.nil?
         incorporationOfImagesFiguresAndTablesNote = ''
       end
       publicPerformanceRight = licenseTerms.xpath(sprintf('./%s', "PublicPerformanceRight/Content")).inner_text
       publicPerformanceNote = licenseTerms.xpath(sprintf('./%s', "PublicPerformanceNote/Content")).inner_text
       trainingMaterialsRight = licenseTerms.xpath(sprintf('./%s', "TrainingMaterialsRight/Content")).inner_text
       trainingMaterialsNote = licenseTerms.xpath(sprintf('./%s', "TrainingMaterialsNote/Content")).inner_text
  #  print "Resources count = " . sizeof($resources);
  #  print "License Count = " . $licenseCount . "\n";
       licenseNames = " id, License_Name, License_ID, Type, Vendor_License_URL, Vendor_License_URL_Visible_In_Public_Display, Vendor_License_URL_Date_Accessed, Second_Vendor_License_URL, Local_License_URL, Local_License_URL_Visible_In_Public_Display, Second_Local_License_URL, Physical_Location, Status, Reviewer, Reviewer_Note, License_Replaced_By, License_Replaces, Execution_Date, Start_Date, End_Date, Advance_Notice_In_Days, License_Note, Template_Note, Date_Created, Last_Updated, Authorized_Users, Authorized_Users_Note, Concurrent_Users, Concurrent_Users_Note, Fair_Use_Clause_Indicator, Database_Protection_Override_Clause_Indicator, All_Rights_Reserved_Indicator, Citation_Requirement_Detail, Digitally_Copy, Digitally_Copy_Note, Print_Copy, Print_Copy_Note, Scholarly_Sharing, Scholarly_Sharing_Note, Distance_Learning, Distance_Learning_Note, ILL_General, ILL_Secure_Electronic, ILL_Electronic_Email, ILL_Record_Keeping, ILL_Record_Keeping_Note, Course_Reserve, Course_Reserve_Note, Electronic_Link, Electronic_Link_Note, Course_Pack_Print, Course_Pack_Electronic, Course_Pack_Note, Remote_Access, Remote_Access_Note, Other_Use_Restrictions_Staff_Note, Other_Use_Restrictions_Public_Note, Perpetual_Access_Right, Perpetual_Access_Holdings, Perpetual_Access_Note, Licensee_Termination_Right, Licensee_Termination_Condition, Licensee_Termination_Note, Licensee_Notice_Period_For_Termination_Number, Licensee_Notice_Period_For_Termination_Unit, Licensor_Termination_Right, Licensor_Termination_Condition, Licensor_Termination_Note, Licensor_Notice_Period_For_Termination_Number, Licensor_Notice_Period_For_Termination_Unit, Termination_Right_Note, Termination_Requirements, Terms_Note, Local_Use_Terms_Note, Governing_Law, Governing_Jurisdiction, Applicable_Copyright_Law, Cure_Period_For_Breach_Number, Cure_Period_For_Breach_Unit, Renewal_Type, Non_Renewal_Notice_Period_Number, Non_Renewal_Notice_Period_Unit, Archiving_Right, Archiving_Format, Archiving_Note, Pre_Print_Archive_Allowed, Pre_Print_Archive_Conditions, Pre_Print_Archive_Restrictions_Number, Pre_Print_Archive_Restrictions_Unit, Pre_Print_Archive_Note, Post_Print_Archive_Allowed, Post_Print_Archive_Restrictions_Number, Post_Print_Archive_Restrictions_Unit, Post_Print_Archive_Note, Incorporation_Of_Images_Figures_And_Tables_Right, Incorporation_Of_Images_Figures_And_Tables_Note, Public_Performance_Right, Public_Performance_Note, Training_Materials_Right, Training_Materials_Note"

       licenseValues = licenseName + "\", \"" + licenseId + "\", \"" + type + "\", \"" + vendorLicenseURL + "\", \"" + vendorLicenseURLVisibleInPublicDisplay + "\", \"" + vendorLicenseURLDateAccessed + "\", \"" + secondVendorLicenseURL  + "\", \"" + localLicenseURL +  "\", \"" + localLicenseURLVisibleInPublicDisplay + "\", \"" + secondLocalLicenseURL + "\", \""  + physicalLocation + "\", \"" + status + "\", \"" + reviewer + "\", \"" + reviewerNote + "\", \"" + licenseReplacedBy + "\", \"" + licenseReplaces + "\", \"" + executionDate + "\", \"" + startDate + "\", \"" + endDate + "\", \"" + advanceNoticeInDays + "\", \"" + licenseNote + "\", \"" + templateNote + "\", \"" + dateCreated + "\", \"" + lastUpdated + "\", \"" + authorizedUsers + "\", \"" + authorizedUsersNote + "\", \"" + concurrentUsers + "\", \"" + concurrentUsersNote + "\", \"" + fairUseClauseIndicator + "\", \"" + databaseProtectionOverrideClauseIndicator + "\", \"" + allRightsReservedIndicator + "\", \"" + citationRequirementDetail + "\", \"" + digitallyCopy + "\", \"" + digitallyCopyNote + "\", \"" + printCopy + "\", \"" + printCopyNote + "\", \"" + scholarlySharing + "\", \"" + scholarlySharingNote + "\", \"" + distanceLearning + "\", \"" + distanceLearningNote + "\", \"" + iLLGeneral + "\", \"" + iLLSecureElectronic + "\", \"" + iLLElectronicEmail + "\", \"" + iLLRecordKeeping + "\", \"" + iLLRecordKeepingNote + "\", \"" + courseReserve + "\", \"" + courseReserveNote + "\", \"" + electronicLink + "\", \"" + electronicLinkNote + "\", \"" + coursePackPrint + "\", \"" + coursePackElectronic + "\", \"" + coursePackNote + "\", \"" + remoteAccess + "\", \"" + remoteAccessNote + "\", \"" + otherUseRestrictionsStaffNote + "\", \"" + otherUseRestrictionsPublicNote + "\", \"" + perpetualAccessRight + "\", \"" + perpetualAccessHoldings + "\", \"" + perpetualAccessNote + "\", \"" + licenseeTerminationRight + "\", \"" + licenseeTerminationCondition + "\", \"" + licenseeTerminationNote + "\", \"" + licenseeNoticePeriodForTerminationNumber + "\", \"" + licenseeNoticePeriodForTerminationUnit + "\", \"" + licensorTerminationRight + "\", \"" + licensorTerminationCondition + "\", \"" + licensorTerminationNote + "\", \"" + licensorNoticePeriodForTerminationNumber + "\", \"" + licensorNoticePeriodForTerminationUnit + "\", \"" + terminationRightNote + "\", \"" + terminationRequirements + "\", \"" + termsNote + "\", \"" + localUseTermsNote + "\", \"" + governingLaw + "\", \"" + governingJurisdiction + "\", \"" + applicableCopyrightLaw + "\", \"" + curePeriodForBreachNumber + "\", \"" + curePeriodForBreachUnit + "\", \"" + renewalType + "\", \"" + nonRenewalNoticePeriodNumber + "\", \"" + nonRenewalNoticePeriodUnit + "\", \"" + archivingRight + "\", \"" + archivingFormat + "\", \"" + archivingNote + "\", \"" + prePrintArchiveAllowed + "\", \"" + prePrintArchiveConditions + "\", \"" + prePrintArchiveRestrictionsNumber + "\", \"" + prePrintArchiveRestrictionsUnit + "\", \"" + prePrintArchiveNote + "\", \"" + postPrintArchiveAllowed + "\", \"" + postPrintArchiveRestrictionsNumber + "\", \"" + postPrintArchiveRestrictionsUnit + "\", \"" + postPrintArchiveNote + "\", \"" + incorporationOfImagesFiguresAndTablesRight + "\", \"" + incorporationOfImagesFiguresAndTablesNote + "\", \"" + publicPerformanceRight + "\", \"" + publicPerformanceNote + "\", \"" + trainingMaterialsRight + "\", \"" + trainingMaterialsNote + "\""

       if resources.size > 0
         resources.each do |resource|
           collectionName = resource.xpath(sprintf('./%s',"CollectionName")).inner_text
           libraryCollectionId = resource.xpath(sprintf('./%s',"LibraryCollectionId")).inner_text
           providerName = resource.xpath(sprintf('./%s',"ProviderName")).inner_text
           providerCode = resource.xpath(sprintf('./%s',"ProviderCode")).inner_text
           databaseName =  resource.xpath(sprintf('./%s',"DatabaseName")).inner_text
           databaseCode =  resource.xpath(sprintf('./%s',"DatabaseCode")).inner_text
           databaseStatus =  resource.xpath(sprintf('./%s',"DatabaseStatus")).inner_text
           titleName = resource.xpath(sprintf('./%s',"TitleName")).inner_text
           titleId =  resource.xpath(sprintf('./%s',"TitleId")).inner_text
           titleStatus = resource.xpath(sprintf('./%s',"TitleStatus")).inner_text
           iSSN =  resource.xpath(sprintf('./%s',"ISSN")).inner_text
           eISSN =  resource.xpath(sprintf('./%s',"eISSN")).inner_text
           iSBN = resource.xpath(sprintf('./%s',"ISBN")).inner_text
           sSID =  resource.xpath(sprintf('./%s',"SSID")).inner_text
           prevailing =  resource.xpath(sprintf('./%s',"Prevailing")).inner_text
           resourceNames = " Collection_Name, Collection_ID, Provider_Name, Provider_Code, Database_Name, Database_Code, Database_Status, Title_Name, Title_ID, Title_Status, ISSN, eISSN, ISBN, SSID, Prevailing"
           resourceValues = " \"" +  collectionName + "\", \"" + libraryCollectionId + "\", \"" + providerName + "\", \"" + providerCode + "\", \"" + databaseName + "\", \"" + databaseCode + "\", \"" + databaseStatus + "\", \"" + titleName + "\", \"" + titleId + "\", \"" + titleStatus + "\", \"" + iSSN + "\", \"" + eISSN + "\", \"" + iSBN + "\", \"" + sSID + "\", \"" + prevailing + "\""
           #output.write("INSERT INTO erm_data (" + licenseNames + ", " + resourceNames + ") VALUES (\"" + licenseCount.to_s + "\", \"" + licenseValues + ", " + resourceValues + ");\n")
           sql = "INSERT INTO erm_data (" + licenseNames + ", " + resourceNames + ") VALUES (\"" + licenseCount.to_s + "\", \"" + licenseValues + ", " + resourceValues + ")"
#            Rails.logger.info("Databases update #{__FILE__} #{__LINE__} sql =  #{sql.inspect}")
           insert = Erm_data.connection.raw_connection.prepare(sql)
           insert.execute
           licenseCount = licenseCount + 1
         end
       else
           #puts "No Resources.\n";
    #       output.write("INSERT INTO erm_data (" + licenseNames + ") VALUES (\"" + licenseCount.to_s + "\", \"" + licenseValues + ");\n")
           sql = "INSERT INTO erm_data (" + licenseNames + ") VALUES (\"" + licenseCount.to_s + "\", \"" + licenseValues + ")"
          # puts sql
           insert = Erm_data.connection.raw_connection.prepare(sql)
           insert.execute
           licenseCount = licenseCount + 1
       end
     end
    end
  end
end
