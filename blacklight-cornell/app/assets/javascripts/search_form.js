document.addEventListener("DOMContentLoaded", function () {
    const advancedSearchLink = document.getElementById("advanced-search-link");
    // Select all inputs, selects, and textareas if no dynamic fields are found
    let formFields = document.querySelectorAll("[data-dynamic='true']");
    if (formFields.length === 0) {
        formFields = document.querySelectorAll("input, select, textarea");
    }

    if (advancedSearchLink && formFields) {
        const searchField = document.getElementById("q");
        // Update the Advanced Search link dynamically
        const updateAdvancedSearchLink = () => {
            let params = new URLSearchParams();
            let hasSearchText = searchField && searchField.value.trim().length > 0;

            formFields.forEach((field) => {
                if (field.name && field.value && field.name !== "q") {
                    const fieldMappings = {
                        authq: "q_row[]",
                        browse_type: "search_field_row[]",
                        search_field: "search_field_row[]"
                    };

                    const searchValueMappings = {
                        author: "author",
                        author_browse: "author",
                        at_browse: "author",
                        "catalog:author": "author",
                        Author: "author",
                        "Author-Title": "author",
                        subject: "subject",
                        subject_browse: "subject",
                        "catalog:subject": "subject",
                        Subject: "subject",
                        publisher: "publisher",
                        "catalog:publisher": "publisher",
                        title: "title",
                        title_starts: "title",
                        "catalog:title": "title",
                        journaltitle: "journaltitle",
                        "catalog:journaltitle": "journaltitle",
                        "catalog:lc_callnum": "lc_callnum",
                        "Call-Number": "lc_callnum",
                        callnumber_browse: "lc_callnum",
                        lc_callnum: "lc_callnum"
                    };

                    if (field.name in fieldMappings) {
                        if (field.name === "browse_type" || field.name === "search_field" || field.name === "search_field_row") {
                            if (field.value in searchValueMappings) {
                                params.append("search_field_row[]", searchValueMappings[field.value]);
                                if (field.value === "title_starts") {
                                    params.append("op_row[]", "begins_with");
                                }
                            }
                        } else {
                            params.append(fieldMappings[field.name], field.value);
                        }
                    } else if (field.name !== "authenticity_token" && field.name !== "utf8") {
                        params.append(field.name, field.value);
                    }
                }
            });

            // Add q_row as a parameter if the search field has text
            if (hasSearchText) {
                params.append("q_row[]", searchField.value.trim()); // Append q_row
            }

            // Append other advanced search parameters if present
            const opRow = document.querySelectorAll("[name='op_row[]']");
            const searchFieldRow = document.querySelectorAll("[name='search_field_row[]']");
            const booleanRow = document.querySelectorAll("[name='boolean_row[]']");
            const facetFields = document.querySelectorAll("[name^='f[']");

            opRow.forEach((field, index) => params.append(`op_row[${index}]`, field.value));
            searchFieldRow.forEach((field, index) => params.append(`search_field_row[${index}]`, field.value));
            booleanRow.forEach((field, index) => params.append(`boolean_row[${index}]`, field.value));

            // Handle facets, including f[format]
            const uniqueFacets = new Set();
            facetFields.forEach((field) => {
                const match = field.name.match(/^f\[(.+)\]$/); // Match f[key] format
                if (match && match[1]) {
                    const key = `f[${match[1]}]`;
                    const value = field.value;
                    const facetEntry = `${key}=${value}`;

                    if (!uniqueFacets.has(facetEntry)) {
                        uniqueFacets.add(facetEntry);
                        params.append(key, value);
                    }
                }
            });
            // Update link href to use the /edit path
            advancedSearchLink.href = `/edit?${params.toString()}`;
        };

        formFields.forEach((field) => {
            field.addEventListener("input", updateAdvancedSearchLink);
            field.addEventListener("change", updateAdvancedSearchLink);
        });
        updateAdvancedSearchLink();
        advancedSearchLink.addEventListener("click", updateAdvancedSearchLink);
    }
});
