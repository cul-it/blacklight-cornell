<?php
$filename = "./licenseData.xml";
if (file_exists($filename)) {
$xml = simplexml_load_file($filename);
#var_dump($xml);
# print_r($xml->LicenseDataResult->License[0]->LicenseName[0]->Label[0]);
  $licenses = $xml->LicenseDataResult->License;
 # print "Number of Licenses = " . sizeof($licenses);
  $licenseCount = 0;
  foreach ($licenses as $license) {
 # print $xml->LicenseDataResult->License[15]->LicenseName[0]->Content[0] . "\n";   
    $licenseCount = $licenseCount + 1;
    $licenseName = $license->LicenseName[0]->Content[0];
    $licenseId = $license->LicenseId[0]->Content[0];
    #print "INSERT INTO erm_data (id) VALUES (" . $licenseCount . ");\n";
    $type = $license->Type[0]->Content[0];
    $vendorLicenseURL = $license->VendorLicenseURL[0]->Content[0];
    $vendorLicenseURLVisibleInPublicDisplay = $license->VendorLicenseURLVisibleInPublicDisplay[0]->Content[0];
    $vendorLicenseURLDateAccessed = $license->VendorLicenseURLDateAccessed[0]->Content[0];
    $secondVendorLicenseURL = $license->SecondVendorLicenseURL[0]->Content[0];
    $localLicenseURL = $license->LocalLicenseURL[0]->Content[0];
    $localLicenseURLVisibleInPublicDisplay = $license->LocalLicenseURLVisibleInPublicDisplay[0]->Content[0];
    $secondLocalLicenseURL = $license->SecondLocalLicenseURL[0]->Content[0];
    $physicalLocation = $license->PhysicalLocation[0]->Content[0];
    $status = $license->Status[0]->Content[0];
    $reviewer = $license->Reviewer[0]->Content[0];
    $reviewerNote = $license->ReviewerNote[0]->Content[0];
    $licenseReplacedBy = $license->LicenseReplacedBy[0]->Content[0];
    $licenseReplaces = $license->LicenseReplaces[0]->Content[0];
    $executionDate = $license->ExecutionDate[0]->Content[0];
    $startDate = $license->StartDate[0]->Content[0];
    $endDate = $license->EndDate[0]->Content[0];
    $advanceNoticeInDays = $license->AdvanceNoticeInDays[0]->Content[0];
    $licenseNote = $license->LicenseNote[0]->Content[0];
    $templateNote = $license->TemplateNote[0]->Content[0];
    $dateCreated = $license->DateCreated[0]->Content[0];
    $lastUpdated = $license->LastUpdated[0]->Content[0];
    $licenseTerms = $license->LicenseTerms[0];
    $resources = $license->LicenseResources[0]->Resource;
    $authorizedUsers = $licenseTerms[0]->AuthorizedUsers[0]->Content[0];
    $authUsers = array();
    foreach($authorizedUsers as $users) {
      $punks = ltrim($users, "\ ");
      array_push($authUsers, $punks);
    }
    $authUsers = implode("|", $authUsers);
    $authorizedUsersNote = $licenseTerms[0]->AuthorizedUsersNote[0]->Content[0];
    $concurrentUsers = $licenseTerms[0]->ConcurrentUsers[0]->Content[0];
    $concurrentUsersNote = $licenseTerms[0]->ConcurrentUsersNote[0]->Content[0];
    $fairUseClauseIndicator = $licenseTerms[0]->FairUseClauseIndicator[0]->Content[0];
    $databaseProtectionOverrideClauseIndicator = $licenseTerms[0]->DatabaseProtectionOverrideClauseIndicator[0]->Content[0];
    $allRightsReservedIndicator = $licenseTerms[0]->AllRightsReservedIndicator[0]->Content[0];
    $citationRequirementDetail = $licenseTerms[0]->CitationRequirementDetail[0]->Content[0];
    $digitallyCopy = $licenseTerms[0]->DigitallyCopy[0]->Content[0];
    $printCopy = $licenseTerms[0]->PrintCopy[0]->Content[0];
    $printCopyNote = $licenseTerms[0]->PrintCopyNote[0]->Content[0];
    $scholarlySharing = $licenseTerms[0]->ScholarlySharing[0]->Content[0];
    $scholarlySharingNote = $licenseTerms[0]->ScholarlySharingNote[0]->Content[0];
    $distanceLearning = $licenseTerms[0]->DistanceLearning[0]->Content[0];
    $iLLGeneral = $licenseTerms[0]->ILLGeneral[0]->Content[0];
    $iLLSecureElectronic = $licenseTerms[0]->ILLSecureElectronic[0]->Content[0];
    $iLLElectronicEmail = $licenseTerms[0]->ILLElectronicEmail[0]->Content[0];
    $iLLRecordKeeping = $licenseTerms[0]->ILLRecordKeeping[0]->Content[0];
    $iLLRecordKeepingNote = $licenseTerms[0]->ILLRecordKeepingNote[0]->Content[0];
    $courseReserve = $licenseTerms[0]->CourseReserve[0]->Content[0];
    $courseReserveNote = $licenseTerms[0]->CourseReserveNote[0]->Content[0];
    $electronicLink = $licenseTerms[0]->ElectronicLink[0]->Content[0];
    $electronicLinkNote = $licenseTerms[0]->ElectronicLinkNote[0]->Content[0];
    $coursePackPrint = $licenseTerms[0]->CoursePackPrint[0]->Content[0];
    $coursePackElectronic = $licenseTerms[0]->CoursePackElectronic[0]->Content[0];
    $coursePackNote = $licenseTerms[0]->CoursePackNote[0]->Content[0];
    $remoteAccess = $licenseTerms[0]->RemoteAccess[0]->Content[0];
    $remoteAccessNote = $licenseTerms[0]->RemoteAccessNote[0]->Content[0];
    $otherUseRestrictionsStaffNote = $licenseTerms[0]->OtherUseRestrictionsStaffNote[0]->Content[0];
    $otherUseRestrictionsPublicNote = $licenseTerms[0]->OtherUseRestrictionsPublicNote[0]->Content[0];
    $perpetualAccessRight = $licenseTerms[0]->PerpetualAccessRight[0]->Content[0];
    $perpetualAccessHoldings = $licenseTerms[0]->PerpetualAccessHoldings[0]->Content[0];
    $perpetualAccessNote = $licenseTerms[0]->PerpetualAccessNote[0]->Content[0];
    $licenseeTerminationRight = $licenseTerms[0]->LicenseeTerminationRight[0]->Content[0];
    $licenseeTerminationCondition = $licenseTerms[0]->LicenseeTerminationCondition[0]->Content[0];
    $licenseeTerminationNote = $licenseTerms[0]->LicenseeTerminationNote[0]->Content[0];
    $licenseeNoticePeriodForTerminationNumber = $licenseTerms[0]->LicenseeNoticePeriodForTerminationNumber[0]->Content[0];
    $licenseeNoticePeriodForTerminationUnit = $licenseTerms[0]->LicenseeNoticePeriodForTerminationUnit[0]->Content[0];
    $licensorTerminationRight[0] = $licenseTerms[0]->LicensorTerminationRight[0]->Content[0];
    $licensorTerminationCondition = $licenseTerms[0]->LicensorTerminationCondition[0]->Content[0];
    $licensorTerminationNote = $licenseTerms[0]->LicensorTerminationNote[0]->Content[0];
    $licensorNoticePeriodForTerminationNumber = $licenseTerms[0]->LicensorNoticePeriodForTerminationNumber[0]->Content[0];
    $licensorNoticePeriodForTerminationUnit = $licenseTerms[0]->LicensorNoticePeriodForTerminationUnit[0]->Content[0];
    $terminationRightNote = $licenseTerms[0]->TerminationRightNote[0]->Content[0];
    $terminationRequirements = $licenseTerms[0]->TerminationRequirements[0]->Content[0];
    $termsNote = $licenseTerms[0]->TermsNote[0]->Content[0];
    $localUseTermsNote = $licenseTerms[0]->LocalUseTermsNote[0]->Content[0];
    $governingLaw = $licenseTerms[0]->GoverningLaw[0]->Content[0];
    $governingJurisdiction = $licenseTerms[0]->GoverningJurisdiction[0]->Content[0];
    $applicableCopyrightLaw = $licenseTerms[0]->ApplicableCopyrightLaw[0]->Content[0];
    $curePeriodForBreachNumber = $licenseTerms[0]->CurePeriodForBreachNumber[0]->Content[0];
    $curePeriodForBreachUnit = $licenseTerms[0]->CurePeriodForBreachUnit[0]->Content[0];
    $renewalType = $licenseTerms[0]->RenewalType[0]->Content[0];
    $nonRenewalNoticePeriodNumber = $licenseTerms[0]->NonRenewalNoticePeriodNumber[0]->Content[0];
    $nonRenewalNoticePeriodUnit = $licenseTerms[0]->NonRenewalNoticePeriodUnit[0]->Content[0];
    $archivingRight = $licenseTerms[0]->ArchivingRight[0]->Content[0];
    $archivingFormat = $licenseTerms[0]->ArchivingFormat[0]->Content[0];
    $archivingNote = $licenseTerms[0]->ArchivingNote[0]->Content[0];
    $prePrintArchiveAllowed = $licenseTerms[0]->PrePrintArchiveAllowed[0]->Content[0];
    $prePrintArchiveConditions = $licenseTerms[0]->PrePrintArchiveConditions[0]->Content[0];
    $prePrintArchiveRestrictionsNumber = $licenseTerms[0]->PrePrintArchiveRestrictionsNumber[0]->Content[0];
    $prePrintArchiveRestrictionsUnit = $licenseTerms[0]->PrePrintArchiveRestrictionsUnit[0]->Content[0];
    $prePrintArchiveNote = $licenseTerms[0]->PrePrintArchiveNote[0]->Content[0];
    $postPrintArchiveAllowed = $licenseTerms[0]->PostPrintArchiveAllowed[0]->Content[0];
    $postPrintArchiveRestrictionsNumber = $licenseTerms[0]->PostPrintArchiveRestrictionsNumber[0]->Content[0];
    $postPrintArchiveRestrictionsUnit = $licenseTerms[0]->PostPrintArchiveRestrictionsUnit[0]->Content[0];
    $postPrintArchiveNote = $licenseTerms[0]->PostPrintArchiveNote[0]->Content[0];
    $incorporationOfImagesFiguresAndTablesRight = $licenseTerms[0]->IncorporationOfImagesFiguresAndTablesRight[0]->Content[0];
    $incorporationOfImagesFiguresAndTablesNote = $licenseTerms[0]->IncorporationOfImagesFiguresAndTablesNote[0]->Content[0];
    $publicPerformanceRight = $licenseTerms[0]->PublicPerformanceRight[0]->Content[0];
    $publicPerformanceNote = $licenseTerms[0]->PublicPerformanceNote[0]->Content[0];
    $trainingMaterialsRight = $licenseTerms[0]->TrainingMaterialsRight[0]->Content[0];
    $trainingMaterialsNote = $licenseTerms[0]->TrainingMaterialsNote[0]->Content[0];
  #  print "Resources count = " . sizeof($resources);
  #  print "License Count = " . $licenseCount . "\n";
  $licenseNames = " id, License_Name, License_ID, Type, Vendor_License_URL, Vendor_License_URL_Date_Accessed, Local_License_URL, Physical_Location, Status, Reviewer, Reviewer_Note, License_Replaced_By, Execution_Date, Start_Date, End_Date, Advance_Notice_in_Days, License_Note, Date_Created, Last_Updated, Template_Note, Authorized_Users, Authorized_Users_Note, Concurrent_Users, Concurrent_Users_Note, ILL_General, ILL_Secure_Electronic, ILL_Electronic_email, ILL_Record_Keeping, ILL_Record_Keeping_Note, Perpetual_Access_Right, Perpetual_Access_Note, Perpetual_Access_Holdings, Archiving_Right, Archiving_Format, Archiving_Note, Incorporation_of_Image_Figures_and_Tables_Right, Incorporation_of_Image_Figures_and_Tables_Note, Public_Performance_Right, Public_Performance_Note, Training_Materials_Right, Training_Materials_Note";
  $licenseValues = "\"" . $licenseName . "\", \"" . $licenseId . "\", \"" . $type . "\", \"" . $vendorLicenseURL . "\", \"" . $vendorLicenseURLDateAccessed . "\", \"" . $localLicenseURL . "\", \"" . $physicalLocation . "\", \"" . $status . "\", \"" . $reviewer . "\", \"" . $reviewerNote . "\", \"" . $licenseReplacedBy . "\", \"" . $executionDate . "\", \"" . $startDate . "\", \"" . $endDate . "\", \"" . $advanceNoticeInDays . "\", \"" . $licenseNote . "\", \"" . $dateCreated . "\", \"" . $lastUpdated . "\", \"" . $templateNote . "\", \"" . $authUsers . "\", \"" . $authorizedUsersNote . "\", \"" . $concurrentUsers . "\", \"" . $concurrentUsersNote . "\", \"" . $iLLGeneral . "\", \"" . $iLLSecureElectronic . "\", \"" . $iLLElectronicEmail . "\", \"" . $iLLRecordKeeping . "\", \"" . $iLLRecordKeepingNote . "\", \"" . $perpetualAccessRight . "\", \"" . $perpetualAccessNote . "\", \"" . $perpetualAccessHoldings . "\", \"" . $archivingRight . "\", \"" . $archivingFormat . "\", \"" . $archivingNote . "\", \"" . $incorporationOfImagesFiguresAndTablesRight . "\", \"" . $incorporationOfImagesFiguresAndTablesNote . "\", \"" . $publicPerformanceRight . "\", \"" . $publicPerformanceNote . "\", \"" . $trainingMaterialsRight . "\", \"" . $trainingMaterialsNote . "\"";
  $resourceSQL = ""; 
  if (sizeof($resources)> 0 ) {
    $top = sizeof($resources);
    for($i = 0; $i < $top; $i++) {
      $collectionName = $resources[$i]->CollectionName;
      $libraryCollectionId = $resources[$i]->LibraryCollectionId;
      $providerName = $resources[$i]->ProviderName;
      $providerCode = $resources[$i]->ProviderCode;
      $databaseName = $resources[$i]->DatabaseName;
      $databaseCode = $resources[$i]->DatabaseCode;
      $databaseStatus = $resources[$i]->DatabaseStatus;
      $titleName = $resources[$i]->TitleName;
      $titleId = $resources[$i]->TitleId;
      $titleStatus = $resources[$i]->TitleStatus;
      $iSSN = $resources[$i]->ISSN;
      $eISSN = $resources[$i]->eISSN;
      $iSBN = $resources[$i]->ISBN;
      $sSID = $resources[$i]->SSID;
      $prevailing = $resources[$i]->Prevailing;
     $resourceNames = " Collection_Name, Collection_ID, Provider_Name, Provider_Code, Database_Name, Database_Code, Database_Status, Title_Name, Title_ID, Title_Status, ISSN, eISSN, ISBN, SSID, Prevailing";
     $resourceValues = " \"" .  $collectionName . "\", \"" . $libraryCollectionId . "\", \"" . $providerName . "\", \"" . $providerCode . "\", \"" . $databaseName . "\", \"" . $databaseCode . "\", \"" . $databaseStatus . "\", \"" . $titleName . "\", \"" . $titleId . "\", \"" . $titleStatus . "\", \"" . $iSSN . "\", \"" . $eISSN . "\", \"" . $iSBN . "\", \"" . $sSID . "\", \"" . $prevailing . "\""; 
     print "INSERT INTO erm_data (" . $licenseNames . ", " . $resourceNames . ") VALUES (\"" . $licenseCount . "\", " . $licenseValues . ", " . $resourceValues . ");\n";
    $licenseCount = $licenseCount + 1;
    } 
  } else {
     # print "No Resources.\n";
      print "INSERT INTO erm_data (" . $licenseNames . ") VALUES (\"" . $licenseCount . "\", " . $licenseValues . ");\n";
  }
   
 # print $license->LicenseName[0]->Content[0] . "\t" . $license->LicenseId[0]->Content[0] . "\n";
  }
} else {
  exit('Failed to open file');
}
?>
