with googl_facebook_company as (
select fabd.ad_date 
	,'Facebook Ads' as media_source
	,fc.campaign_name 
	,fa.adset_name
	,spend
	,impressions
	,reach
	,clicks
	,leads
	,value
from facebook_ads_basic_daily fabd 
	join facebook_adset fa on fa.adset_id =fabd.adset_id 
	join facebook_campaign fc  on fc.campaign_id  =fabd.campaign_id 
union 
select ad_date
	,'Google Ads' as media_source
	,campaign_name
	,adset_name
	,spend
	,impressions
	,reach
	,clicks
	,leads
	,value
from google_ads_basic_daily gabd
)
select ad_date 
	,media_source
	,campaign_name
	,adset_name
	,sum(spend)			as sum_spend
	,sum(impressions) 	as sum_impressions
	,sum(clicks)  		as sum_clicks
	,sum(value) 		as sum_value
from googl_facebook_company
group by 1,2,3,4
order by 8 desc 
;
