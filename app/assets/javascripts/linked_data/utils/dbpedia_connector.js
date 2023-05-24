function DbpediaConnector() {
  async function query(sparqlQuery) {
    const dbpediaUrl = 'https://dbpedia.org/sparql';
    const fullQuery = `${dbpediaUrl}?query=${encodeURIComponent(sparqlQuery)}&format=json`;
    return $.ajax({
      url: fullQuery,
      headers: { Accept: 'application/sparql-results+json' },
      dataType: 'jsonp',
      'jsonp': 'callback',
    });
  }

  function parseData(data) {
    const dbpOutput = {};
    const bindings = data?.results?.bindings;
    if (bindings && bindings.length) {
      const { comment, uri } = bindings[0];
      if (comment?.value) {
        dbpOutput.description = comment.value;
        dbpOutput.uri = uri?.value;
      }
    }
    return dbpOutput;
  };

  async function getData(sparqlQuery) {
    const results = await query(sparqlQuery);
    return parseData(results);
  }

  return {
    getData,
  };
}
