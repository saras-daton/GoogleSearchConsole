{% if var('Sitemaps') %}
    {{ config( enabled = True ) }}
{% else %}
    {{ config( enabled = False ) }}
{% endif %}

    {% if is_incremental() %}
    {%- set max_loaded_query -%}
    SELECT coalesce(MAX(_daton_batch_runtime) - 2592000000,0) FROM {{ this }}
    {% endset %}

    {%- set max_loaded_results = run_query(max_loaded_query) -%}

    {%- if execute -%}
    {% set max_loaded = max_loaded_results.rows[0].values()[0] %}
    {% else %}
    {% set max_loaded = 0 %}
    {%- endif -%}
    {% endif %}

    {% set table_name_query %}
    {{set_table_name('%sitemaps')}}    
    {% endset %} 


    {% set results = run_query(table_name_query) %}
    {% if execute %}
    {# Return the first column #}
    {% set results_list = results.columns[0].values() %}
    {% else %}
    {% set results_list = [] %}
    {% endif %}


    {% for i in results_list %}
        {% if var('get_brandname_from_tablename_flag') %}
            {% set brand =i.split('.')[2].split('_')[var('brandname_position_in_tablename')] %}
        {% else %}
            {% set brand = var('default_brandname') %}
        {% endif %}

        {% if var('get_storename_from_tablename_flag') %}
            {% set store =i.split('.')[2].split('_')[var('storename_position_in_tablename')] %}
        {% else %}
            {% set store = var('default_storename') %}
        {% endif %}

        SELECT * {{exclude()}} (row_num)
        From (
            select 
            '{{brand}}' as brand,
            '{{store}}' as store,
			a.* {{exclude()}} (_daton_user_id, _daton_batch_runtime, _daton_batch_id),
			a._daton_user_id,
            a._daton_batch_runtime,
            a._daton_batch_id,
			current_timestamp() as _last_updated,
			'{{env_var("DBT_CLOUD_RUN_ID", "manual")}}' as _run_id,
			from (
				path,
				lastSubmitted,
				isPending,
				isSitemapsIndex,
				type,
				lastDownloaded,
				warnings,
				errors,
				{% if target.type=='snowflake' %} 
					contents.VALUE:type :: varchar as type,
					contents.VALUE:submitted :: varchar as submitted,
					contents.VALUE:indexed :: varchar as indexed,
				{% else %}
					coalesce(contents.type,'') as type,
					coalesce(contents.submitted,'') as submitted,
					coalesce(contents.indexed,'') as indexed,
				{% endif %}
				{{daton_user_id()}} as _daton_user_id,
				{{daton_batch_runtime()}} as _daton_batch_runtime,
				{{daton_batch_id()}} as _daton_batch_id,
				DENSE_RANK() OVER (PARTITION BY path order by {{daton_batch_runtime()}} desc) row_num
            from {{i}}
				{{unnesting("contents")}}
                {% if is_incremental() %}
					{# /* -- this filter will only be applied on an incremental run */ #}
					WHERE {{daton_batch_runtime()}}  >= {{max_loaded}}
                {% endif %} 
			) a
        )
        where row_num = 1 
        {% if not loop.last %} union all {% endif %}
    {% endfor %}