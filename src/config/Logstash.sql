#Query to import data through logstash into elasticsearch (config file: Config/transactions.conf)
#Get set fiscal year from date_effective field
SELECT CASE 
	WHEN t.date_effective BETWEEN '2017-06-01' AND '2018-05-31' THEN '2018'
	WHEN t.date_effective BETWEEN '2016-06-01' AND '2017-05-31' THEN '2017'
	WHEN t.date_effective BETWEEN '2015-06-01' AND '2016-05-31' THEN '2016'
	WHEN t.date_effective BETWEEN '2014-06-01' AND '2015-05-31' THEN '2015'
    WHEN t.date_effective BETWEEN '2013-06-01' AND '2014-05-31' THEN '2014'
    WHEN t.date_effective BETWEEN '2012-06-01' AND '2013-05-31' THEN '2013'
    WHEN t.date_effective BETWEEN '2011-06-01' AND '2012-05-31' THEN '2012'
    WHEN t.date_effective BETWEEN '2010-06-01' AND '2011-05-31' THEN '2011'
    WHEN t.date_effective BETWEEN '2009-06-01' AND '2010-05-31' THEN '2010'
    WHEN t.date_effective BETWEEN '2008-06-01' AND '2009-05-31' THEN '2009'
    WHEN t.date_effective BETWEEN '2007-06-01' AND '2008-05-31' THEN '2008'
    WHEN t.date_effective BETWEEN '2006-06-01' AND '2007-05-31' THEN '2007'
    WHEN t.date_effective BETWEEN '2005-06-01' AND '2006-05-31' THEN '2006'
    WHEN t.date_effective BETWEEN '2004-06-01' AND '2005-05-31' THEN '2005'
    ELSE null
END as fiscal_year, YEAR(t.date_effective) as year, MONTH(t.date_effective) as month,
CASE 
	#Special Sales: Closeouts, author sales, other special sales
	WHEN co.value IN ('SSAUT', 'CLST', 'SSOTH') and isa.value NOT LIKE ('%Special%') then 'Special'
    #Custom Bible Sales
    WHEN i.product_type = 'bible' and isa.value LIKE ('%Special%') then 'Custom'
    #Conference Sales
    WHEN cos.value = 'convention' then 'Conference'
    ELSE 'Normal'
END as sale_type, 
t.id as invoice_credit_id, t.transaction_id, IFNULL(cosa.value, '') as po_number, t.id_type, i.id as item_id, 
IFNULL(s1.value, '') as tract_bible_version, i.itemcode, 
IFNULL(Coalesce(s.value, sa.value), '') as isbn_13,
i.title, t.item_id as item_id_old, t.title as title_old, i.print_status, IFNULL(isat.value, '') as format, IFNULL(atr.value, '') as cover_design,
IFNULL(att.value, '') as author, IFNULL(ta.value, '') as short_description,
IFNULL(cs.value, 'unassigned') as sales_rep, 
CASE
	 WHEN i.product_type = 'tract' then 'Tract'
     WHEN i.product_type = 'Calendar Card' then 'Other'
     WHEN i.product_type = 'video' then 'Other'
     WHEN i.product_type = 'audio' then 'Other'
     WHEN i.product_type = 'booklet' then 'Other'
     WHEN i.product_type = 'other' then 'Other'
     ELSE i.product_type
END as category,
i.price_1 as msrp, 
#Change book categories
CASE
	WHEN i.product_type = 'book' and i.category LIKE ('Electronic%') then 'Digital'
    WHEN i.product_type = 'book' and i.category NOT LIKE ('Electronic%') then 'Print'
    WHEN i.product_type = 'bible' then tr.translation
    WHEN i.product_type = 'tract' then 'Tract'
    ELSE 'Other'
END as sub_category, 
CASE
	WHEN i.product_type = 'bible' and a.value IN ('BB Online', 'BB Electronic') then 'Digital'
    ELSE i.category
END as product_line, t.customer_id, c.customer_category, 
#Combine different billing accounts, Barnes&Noble, Family, Noble
CASE
	WHEN c.name LIKE 'Barnes/%' THEN 'Barnes & Noble'
    WHEN c.name LIKE 'Barnes &%' THEN 'Barnes & Noble'
    WHEN c.id IN ('737683', '436000') THEN 'Family Christian'
    WHEN cs.value IN ('Smith', 'Smith, Mat', 'Noble Marketing', 'Terry', 'Terry, Ted', 'Millen', 'Millen, Sherron', 
		'Treloar', 'Treloar, Scott', 'Garrett', 'Garrett, Ryan', 'Davis', 'Davis, Lane', 'Terry, Jon', 'Gortmaker', 'Gortmaker, Jerry',
        'Gunden', 'Gunden, Doug', 'Terry, David', 'Read', 'Read, Alan', 'NE Rep', 'Smith', 'Smith, Mat', 'Noble Marketing', 'Noble')
        THEN 'Noble'
    ELSE c.name 
 END as customer_name,
SUM(t.price_extended) as net_sales, SUM(t.qty_sold*t.price_list) as order_value, 
1-(SUM(t.price_extended)/SUM(t.qty_sold*t.price_list)) as avg_discount, 
DATE_FORMAT(t.date_effective, '%Y-%m-%d') as date_effective,
CASE
	WHEN i.title LIKE '%25-Pack%' then SUM(t.qty_sold*25)
    ELSE SUM(t.qty_sold)
END as net_units,
IFNULL(SUM(t.cost_inventory), 0) as cost_inventory, IFNULL(SUM(t.cost_royalty), 0) as cost_royalty, co.value as source  
FROM item_transactions t 
#Join for sales_rep to evaluate if Noble, for orders and returns
left join co_string_attributes cs on t.customer_id = cs.id and cs.type ='customers' and cs.attribute = 'salesrep' and cs.id > 0 
left join co_string_attributes cosa on t.id = cosa.id and t.id_type = 'invoice' and cosa.type ='orders' and cosa.attribute = 'po_number' 
join items_index i on t.current_edition_item_id = i.id
left join translations tr on i.category = tr.abbrev and tr.type = 'tswed_bible_categories'
left join i_string_attributes s on t.current_edition_item_id = s.id and s.type = 'items' and s.attribute = 'isbn_13'
left join i_string_attributes sa on t.current_edition_item_id = sa.id and sa.type = 'items' and sa.attribute = 'isbn_upc'
left join i_string_attributes sat on t.current_edition_item_id = sat.id and sat.type = 'items' and sat.attribute = 'category'
left join i_string_attributes isa on t.current_edition_item_id = isa.id and isa.type = 'items' and isa.attribute = 'season'
left join i_string_attributes isat on t.current_edition_item_id = isat.id and isat.type = 'items' and isat.attribute = 'format'
left join i_string_attributes a on i.id = a.id and a.type = 'items' and a.attribute = 'series'
left join i_string_attributes att on t.current_edition_item_id = att.id and att.type = 'items' and att.attribute = 'author'
left join i_string_attributes atr on t.current_edition_item_id = atr.id and atr.type = 'items' and atr.attribute = 'title_supplement'
left join i_string_attributes s1 on t.current_edition_item_id = s1.id and s1.type = 'items' and s1.attribute = 'bible_version'
left join i_text_attributes ta on t.current_edition_item_id = ta.id and ta.type = 'items' and ta.attribute = 'description_short'
left join i_boolean_attributes b on t.item_id = b.id and b.type = 'items' and b.attribute = 'amazon_in_stock_protection'
join customers c on t.customer_id = c.id 
left join co_string_attributes co on t.id = co.id and co.type = 'orders' and co.attribute = 'source'
left join co_string_attributes cos on t.id = cos.id and cos.type = 'orders' and cos.attribute = 'order_method'
WHERE t.date_effective BETWEEN '2017-02-01' AND '2017-02-31' 
and t.id_type in ('invoice', 'credit') and t.item_id <> 8099
and t.transaction_type in ('sale', 'return', 'return_nts') and i.category NOT IN ('donation', 'membership', 'fee')  
GROUP BY t.transaction_id