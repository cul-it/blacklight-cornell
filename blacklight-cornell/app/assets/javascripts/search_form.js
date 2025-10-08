document.addEventListener("DOMContentLoaded", function () {
    const advancedSearchLink = document.getElementById("advanced-search-link");
    // Select simple search and browse form fields
    let formFields = document.querySelectorAll("input#q, select#search_field, input#authq, select#browse_type");

    if (advancedSearchLink && formFields) {
        const searchField = document.getElementById("q");
        // Update the Advanced Search link dynamically
        const updateAdvancedSearchLink = () => {
            let advancedSearchLinkParams = new URLSearchParams(advancedSearchLink.href.split("?")[1]);
            let hasSearchText = searchField && searchField.value.trim().length > 0;

            formFields.forEach((field) => {
                if (field.name && field.value && field.name !== "q") {
                    const fieldMappings = {
                        authq: "q_row[]",
                        browse_type: "search_field_row[]",
                        search_field: "search_field_row[]"
                    };

                    const searchValueMappings = {
                        all_fields: "all_fields",
                        "catalog:all_fields": "all_fields",
                        author: "author",
                        author_browse: "author",
                        at_browse: "author",
                        "catalog:author": "author",
                        subject: "subject",
                        subject_browse: "subject",
                        "catalog:subject": "subject",
                        publisher: "publisher",
                        "catalog:publisher": "publisher",
                        title: "title",
                        title_starts: "title",
                        "catalog:title": "title",
                        journaltitle: "journaltitle",
                        "catalog:journaltitle": "journaltitle",
                        "catalog:lc_callnum": "lc_callnum",
                        callnumber_browse: "lc_callnum",
                        lc_callnum: "lc_callnum"
                    };

                    if (field.name in fieldMappings) {
                        if (field.name === "browse_type" || field.name === "search_field") {
                            if (field.value in searchValueMappings) {
                                advancedSearchLinkParams.set("search_field_row[]", searchValueMappings[field.value]);
                                if (field.value === "title_starts") {
                                    advancedSearchLinkParams.set("op_row[]", "begins_with");
                                }
                            }
                        } else {
                            advancedSearchLinkParams.set(fieldMappings[field.name], field.value);
                        }
                    }
                }
            });

            // Add q_row as a parameter if the search field has text
            if (hasSearchText) {
                advancedSearchLinkParams.set("q_row[]", searchField.value.trim()); // Append q_row
            }

            // Update link href to use the /edit path
            advancedSearchLink.href = `/edit?${advancedSearchLinkParams.toString()}`;
        };

        formFields.forEach((field) => {
            field.addEventListener("input", updateAdvancedSearchLink);
            field.addEventListener("change", updateAdvancedSearchLink);
        });
    }
});
