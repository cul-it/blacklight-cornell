document.addEventListener("DOMContentLoaded", function () {
    const advancedSearchLink = document.getElementById("advanced-search-link");
    // Select all inputs, selects, and textareas if no dynamic fields are found
    let formFields = document.querySelectorAll("[data-dynamic='true']");
    if (formFields.length === 0) {
        console.warn("No fields with data-dynamic found! Falling back to all form elements.");
        formFields = document.querySelectorAll("input, select, textarea");
    }

    if (advancedSearchLink && formFields) {
        // Function to update the Advanced Search link dynamically
        const updateAdvancedSearchLink = () => {
            let params = new URLSearchParams();

            formFields.forEach((field) => {
                if (field.name && field.value) {
                    // Mapping for browse-specific parameters
                    const fieldMappings = {
                        authq: "q",
                        browse_type: "search_field",
                        search_field: "search_field"
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

                    // Check if the field name needs special mapping
                    if (field.name in fieldMappings) {
                        if (field.name === "browse_type" || field.name === "search_field") {
                            if (field.value in searchValueMappings) {
                                params.append("search_field", searchValueMappings[field.value]);
                            }
                        } else {
                            params.append(fieldMappings[field.name], field.value);
                        }
                    } else if (field.name !== "authenticity_token" && field.name !== "utf8") {
                        // Add other fields except unnecessary ones
                        params.append(field.name, field.value);
                    }
                }
            });
            // Update the href of the link
            advancedSearchLink.href = `/advanced?${params.toString()}`;
        };

        // Add event listeners to form fields for dynamic updates
        formFields.forEach((field) => {
            field.addEventListener("input", updateAdvancedSearchLink);
            field.addEventListener("change", updateAdvancedSearchLink);
        });

        // Ensure the link updates on page load
        updateAdvancedSearchLink();

        // Ensure params are updated on click as a fallback
        advancedSearchLink.addEventListener("click", updateAdvancedSearchLink);
    }
});
