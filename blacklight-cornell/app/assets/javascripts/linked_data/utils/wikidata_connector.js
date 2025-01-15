function WikidataConnector() {
  // Does not allow cc2 or cc2.5
  const allowedLicenses = [
    'pd',
    'cc0',
    'cc-by-1.0',
    'cc-by-3.0',
    'cc-by-4.0',
    'cc-by-sa-1.0',
    'cc-by-sa-3.0',
    'cc-by-sa-4.0'
  ];
  const supportedImageTypes = ['jpg', 'jpeg', 'gif', 'png', 'svg'];
  const imageSparqlSelect = '?image ?imageLicense ?imageLicenseShortName ?imageLicenseUrl ?imageArtist ?imageName ?imageTitle';

  // Fetches optional image and image license information for attribution display and filtering by license type
  // Uses MediaWiki API service to query wikimedia for image file license data
  // https://www.mediawiki.org/wiki/Wikidata_Query_Service/User_Manual/MWAPI
  const imageSparqlWhere = (
    'OPTIONAL { '
      + '?entity wdt:P18 ?image. '
      + 'BIND(STRAFTER(wikibase:decodeUri(STR(?image)), "http://commons.wikimedia.org/wiki/Special:FilePath/") AS ?fileTitle) '
      + 'SERVICE wikibase:mwapi { '
        + 'bd:serviceParam wikibase:endpoint "commons.wikimedia.org"; '
                        + 'wikibase:api "Generator"; '
                        + 'wikibase:limit "once"; '
                        + 'mwapi:generator "allpages"; '
                        + 'mwapi:gapfrom ?fileTitle; '
                        + 'mwapi:gapnamespace 6; '
                        + 'mwapi:gaplimit 1; '
                        + 'mwapi:prop "imageinfo"; '
                        + 'mwapi:iiprop "extmetadata". '
        + '?imageLicense wikibase:apiOutput "imageinfo/ii/extmetadata/License/@value". '
        + '?imageLicenseShortName wikibase:apiOutput "imageinfo/ii/extmetadata/LicenseShortName/@value". '
        + '?imageLicenseUrl wikibase:apiOutput "imageinfo/ii/extmetadata/LicenseUrl/@value". '
        + '?imageArtist wikibase:apiOutput "imageinfo/ii/extmetadata/Artist/@value". '
        + '?imageName wikibase:apiOutput "imageinfo/ii/extmetadata/ObjectName/@value". '
        + '?imageTitle wikibase:apiOutput mwapi:title. '
      + '} '
    + '}'
  );

  function isSupportedImage(image) {
    return !!image?.title && isSupportedImageType(image?.url) && isSupportedLicense(image?.license);
  }

  // Only display images with certain file types
  function isSupportedImageType(imageUrl) {
    if (!imageUrl) return false;

    const fileExtension = imageUrl.substr(imageUrl.lastIndexOf('.') + 1).toLowerCase();
    return supportedImageTypes.includes(fileExtension);
  }

  // Don't display images licensed by cc2
  function isSupportedLicense(imageLicense) {
    return allowedLicenses.includes(imageLicense?.toLowerCase());
  }
  
  async function getData(sparqlQuery) {
    return $.ajax({
      url: 'https://query.wikidata.org/sparql',
      headers: { Accept: 'application/sparql-results+json' },
      data: { query: sparqlQuery }
    });
  }

  // TODO: Strip html from Wikidata response?
  //       Example where response doesn't fit in below format: "Shakespeare, William, 1564-1616." (headingType=[subject, author])
  function imageAttributionHtml(image) {
    const wmcUrl = `https://commons.wikimedia.org/wiki/${encodeURIComponent(image.title)}`;
    const titleHtml = `"<a href="${wmcUrl}">${image.name || image.title}</a>"`;
    const licenseName = image.licenseShortName || image.license;
    const licenseHtml = image.licenseUrl ?
      ` / <a href="${image.licenseUrl}">${licenseName}</a>` :
      ` / ${licenseName}`;
    const artistHtml = image.artist ? ` by ${image.artist}`: '';
    return `${titleHtml}${artistHtml}${licenseHtml}`;
  }

  return {
    getData,
    imageAttributionHtml,
    imageSparqlSelect,
    imageSparqlWhere,
    isSupportedImage,
  }
}
