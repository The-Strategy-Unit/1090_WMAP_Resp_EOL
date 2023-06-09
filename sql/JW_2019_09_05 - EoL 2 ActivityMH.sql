----------------------------------------------------------------------------------------------------------------------------------------------------
/*create the correct mental health contact activity file (linking via MH MPI) with added fields and linked to MPI*/
----------------------------------------------------------------------------------------------------------------------------------------------------
--drop table ActivityMH
select SUPatID
	,MPI.BB5008_Pseudo_ID--Der_Pseudo_NHS_Number
	,'MH' as ActivityType
	--,Carer_Support_Indicator
	--,NHSDEthnicity
	,CareContDate
	--DON'T HAVE ,Der_Provider_Code --provider code, 3 digits except for private
	--DON'T HAVE ,Der_Provider_Site_Code --provider code, 5 digits except for private. don't think will use but just in case I am including for now
	,ContLocDistanceHome
	,BB5008_Pseudo_MHSDS_CareContactId
	,'MHCON' as PODSubGroup
	,'MH' as PODSummaryGroup
	,'PlannedContact' as PODType
	,AdminCatCode
	,ConsType
	,ActLocTypeCode
	--,Grand_Total_Payment_MFF_Cost1819
	,SpecialisedMHServiceCode
	--,Responsible_Purchaser_Type_Der1819 --summary version
	--,Responsible_Purchaser_Assignment_Method_Der1819 --detailed version
	,''as SSFlag
	,999999 as Der_Provider_Patient_Distance_Miles
	,cast(case 
		when datepart(d,REG_DATE_OF_DEATH)<datepart(d,CareContDate) then cast(datediff(mm,CareContDate,REG_DATE_OF_DEATH)-1 as nvarchar(8))
		when datepart(d,REG_DATE_OF_DEATH)>=datepart(d,CareContDate) then cast(datediff(mm,CareContDate,REG_DATE_OF_DEATH) as nvarchar(8))
	end as int) as ProximityToDeath
	,cast(datediff(d,CareContDate,REG_DATE_OF_DEATH) as int) as ProximityToDeathDays--does this ned to be int?
	,case when cast(datediff(d,CareContDate,REG_DATE_OF_DEATH) as int)=0 then '24hours'
		when cast(datediff(d,CareContDate,REG_DATE_OF_DEATH) as int)= 1then '48hours'
		when cast(datediff(d,CareContDate,REG_DATE_OF_DEATH) as int) between 2 and 6 then '1weeks'
		when cast(datediff(d,CareContDate,REG_DATE_OF_DEATH) as int) between 7 and 13 then '2weeks'
	end as ProximityToDeathDaysCategory
	,STP18CD
	,CCGResponsible
	,DER_AGE_AT_DEATH
	,LocationType
	,CauseGroupLL
into ActivityMH
from 
	(
	select BB5008_Pseudo_ID
		,BB5008_Pseudo_MHSDS_Person_ID
	from [qa].[tbl_MHSDS_MHS001MPI_Extract] as A
	group by BB5008_Pseudo_ID
		,BB5008_Pseudo_MHSDS_Person_ID
	) as MHP
inner join qa.tbl_MHSDS_MHS201CareContact_Extract as MHC
	on MHP.BB5008_Pseudo_MHSDS_Person_ID=MHC.BB5008_Pseudo_MHSDS_Person_ID
inner join MPI as MPI
	on MPI.BB5008_Pseudo_ID=MHP.BB5008_Pseudo_ID
where 
1=1
and cast(case 
		when datepart(d,MPI.REG_DATE_OF_DEATH)<datepart(d,MHC.CareContDate) then cast(datediff(mm,MHC.CareContDate,MPI.REG_DATE_OF_DEATH)-1 as nvarchar(8))
		when datepart(d,MPI.REG_DATE_OF_DEATH)>=datepart(d,MHC.CareContDate) then cast(datediff(mm,MHC.CareContDate,MPI.REG_DATE_OF_DEATH) as nvarchar(8))
	end as int)<=23 --between 0 and 23
and AttendOrDNACode in ('5','6')