with googl_facebook_company as (
select 
	ad_date
	,url_parameters
	,coalesce (spend,0) as spend
	,coalesce (impressions,0) as impressions
	,coalesce (reach,0) as reach
	,coalesce (clicks,0) as clicks
	,coalesce (leads,0) as leads
	,coalesce (value,0)	as value
from facebook_ads_basic_daily fabd 
where ad_date is not null
union 
select 
	ad_date
	,url_parameters
	,coalesce (spend,0) as spend
	,coalesce (impressions,0) as impressions
	,coalesce (reach,0) as reach
	,coalesce (clicks,0) as clicks
	,coalesce (leads,0) as leads
	,coalesce (value,0)	as value
from google_ads_basic_daily gabd
where ad_date is not null
), agr_gl_fc_comp as ( 
select 
	date (date_trunc( 'month', ad_date)) as ad_month
	,case when lower(substring(url_parameters,'utm_campaign=([^&#$]+)'))='nan' 
		then null else lower(substring(url_parameters,'utm_campaign=([^&#$]+)')) end as utm_campaign
	,sum(spend)			as sum_spend
	,sum(impressions) 	as sum_impressions
	,sum(clicks)  		as sum_clicks
	,sum(value) 		as sum_value
	,case when sum(clicks)>0
		then round(sum(spend)::numeric /sum(clicks),2) else 0 end  as CPC --ціна одного кліка
	,case when sum(impressions)>0
		then round (sum(spend)*1000/sum(impressions)::numeric,2) else 0 end  as CPM --вартість банера на 1000
	,case when sum(impressions)>0
		then round(sum(clicks)::numeric/sum(impressions)*100,2) else 0 end  as CTR --ефективність банера %
	,case when sum(spend)>0
		then round( (sum(value)::numeric -sum(spend))/sum(spend)*100,2) else 0 end as ROMI --витрати на рекламу%
from googl_facebook_company gfc
group by 1,2
order by 3 desc 
), differences as (
select 
	agr_1m.ad_month as diff_ad_month
	,agr_1m.utm_campaign as diff_utm_campaign
	,round(sum(case when ctr_cmp_romi_1m.romi >0 
			  then (agr_1m.romi-ctr_cmp_romi_1m.romi)/ctr_cmp_romi_1m.romi end),2) as diff_romi 
	,round(sum(case when ctr_cmp_romi_1m.cpm >0 
			  then (agr_1m.cpm-ctr_cmp_romi_1m.cpm)/ctr_cmp_romi_1m.cpm end),2) as diff_cpm
	,round(sum(case when ctr_cmp_romi_1m.ctr >0 
			  then (agr_1m.ctr-ctr_cmp_romi_1m.ctr)/ctr_cmp_romi_1m.ctr end),2) as diff_ctr
from agr_gl_fc_comp as agr_1m
left join agr_gl_fc_comp as ctr_cmp_romi_1m  
    on agr_1m.ad_month = ctr_cmp_romi_1m.ad_month + INTERVAL '1 month'
    group by 1,2
)
select 
	agr_gl_fc_comp.ad_month
	,agr_gl_fc_comp.utm_campaign
	,agr_gl_fc_comp.sum_spend
	,agr_gl_fc_comp.sum_impressions
	,agr_gl_fc_comp.sum_clicks
	,agr_gl_fc_comp.sum_value
	,agr_gl_fc_comp.CPC
	,agr_gl_fc_comp.CPM
	,agr_gl_fc_comp.CTR
	,agr_gl_fc_comp.ROMI
	,diff.diff_cpm
	,diff.diff_ctr
	,diff.diff_romi
from agr_gl_fc_comp 
left join differences as diff 
	on agr_gl_fc_comp.ad_month = diff.diff_ad_month 
	and agr_gl_fc_comp.utm_campaign=diff.diff_utm_campaign
;
