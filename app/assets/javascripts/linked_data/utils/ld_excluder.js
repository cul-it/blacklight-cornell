function LDExcluder() {
  const exclusionsJSON = getExclusions();
  const exclusionPropertiesHash = createExclusionHash();
  const entityIsNotExcluded = displayAuthExternalData();

  // Method for reading exclusion information i.e whether Wikdiata/DbPedia info will be allowed for this heading
  function getExclusions() {
    const exclusionsInput = $('#exclusions');
    if (exclusionsInput.length && exclusionsInput.val() != '') {
      return JSON.parse(exclusionsInput.val());
    }
    return null;
  };
  
  // Is all external data not to be displayed for authority? If authority is present in the list and has no properties
  // false if external data should not be displayed at all for this authority
  function displayAuthExternalData() {
    //no exclusions, or exclusion = false, or exclusion is true but there are properties
    return (exclusionsJSON == null || $.isEmptyObject(exclusionsJSON) ||
      ('exclusion' in exclusionsJSON && (exclusionsJSON['exclusion'] == false) ) ||
      ('exclusion' in exclusionsJSON && exclusionsJSON['exclusion'] == true && 'properties' in exclusionsJSON && exclusionsJSON['properties'].length));
  };

  function isPropertyExcluded(propertyName) {
    // if this property exists in our hash, then that means it is one of the properties the yaml 
        // file indicates should not be displayed
    return propertyName in exclusionPropertiesHash;
  };

  function createExclusionHash() {
    const exclusionHash = {};
    if('properties' in exclusionsJSON && exclusionsJSON['properties'].length) {
      $.each(exclusionsJSON.properties, function(i, v) {
        exclusionHash[v] = true;
      });
    }
    return exclusionHash;
  };

  return {
    entityIsNotExcluded,
    isPropertyExcluded,
  }
}