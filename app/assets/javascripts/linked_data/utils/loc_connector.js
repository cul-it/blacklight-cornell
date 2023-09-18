function LOCConnector() {
  // Lookup suggestions in LOC for given name query
  async function getLocalName(locQuery, rdfType) {
    const lookupURL = `https://id.loc.gov/authorities/names/suggest?q=${encodeURIComponent(locQuery)}&rdftype=${rdfType}&count=1`;
    // Using timeout to handle query that doesn't return in 3 seconds for jsonp request
    const results = await $.ajax({
      url: lookupURL,
      dataType: 'jsonp',
      timeout: 3000,
      crossDomain: true
    });
    return parseResults(results);
  };
    
  // Example LOC results:
  // [
  //   "Vivaldi, Antonio, 1678-1741",
  //   ['Vivaldi, Antonio, 1678-1741'],
  //   ['1 result'],
  //   ['http://id.loc.gov/authorities/names/n79021280']
  // ]
  function parseResults(suggestions) {
    if (suggestions && suggestions.length > 3 && suggestions[1] !== undefined) {
      const locURI = suggestions[3][0];
      // Get string right after last slash if it's present
      return locURI?.split('/')?.pop();
    }
  };

  return { getLocalName }
}
