USE [ephemera]
GO
/****** Object:  StoredProcedure [dbo].[COLLECTOR]    Script Date: 25.07.2014 11:22:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[COLLECTOR]
AS
BEGIN
	declare  @store			varchar(50),			
			 @kasSrv		nvarchar(50),	-- KASSRVxxx\SQLNETxxx					'KASSRV007\SQLNET007'
			 @kasDb			nvarchar(50),	-- CashDBxxx							quotename('KASSRV007\SQLNET007')
			 @kasFullName	nvarchar(128),  -- [KASSRVxxx\SQLNETxxx].[CashDBxxx]
			 @stringSQL		nvarchar(4000),
			 @stringSQL2	nvarchar(4000),
			 @stringSQL3	nvarchar(4000),
			 @stringSQL4	nvarchar(4000),
			 @active_tran	nvarchar(max),
			 @UpdateLinks	bit,
			 @LinksExists	bit,
			 @reflect		bit,
			 @load			int,
			 @ErrorCode		int,
			 @CURSOR		cursor;
	declare  @newDay int;	set @newDay = 0;
	declare  @retval int;	set @retval = 0;
	declare	 @cnt	 int;	set @cnt    = 0;
	-- Error code:
	--				10 - sp_testlinkedserver failed
	--				20 - kasDb is unable
	--				30 - DWH crushed, rebuild only
	SET XACT_ABORT ON;
	SET NOCOUNT ON;
	
	set @UpdateLinks = 0;	--<<-- если надо проапдейтить линки - 1, нет - 0
	--print 'Getting started ' + convert(varchar, SYSDATETIME());

	--Zero_DWH: execute dbo.ZERO_TABLESPACE;
	select @newDay = (select count(1) from bon_common);
	if @newDay > 0 select @newDay = (select top 1 datediff(day, convert(date, b.date_beg), GETDATE()) from bon_common b);
	if @newDay > 0 execute dbo.ZERO_TABLESPACE;

	SET @CURSOR  = CURSOR SCROLL FOR SELECT STORECODE, SRVNAME, DBNAME FROM COMPANY;
	
	--print 'Extraction data from each remote servers...';
	OPEN @CURSOR FETCH NEXT FROM @CURSOR INTO @store, @kasSrv, @kasDb;
	while @@FETCH_STATUS = 0
	BEGIN
		set @kasFullName = quotename(ltrim(@kasSrv)) +'.'+ quotename(ltrim(@kasDb));						-- ловим версию сервера
		--print convert(varchar, @store) +' '+ @kasSrv +' '+ @kasDb +' '+ @kasFullName;		return;

		select @LinksExists = (select count(1) from sys.servers where name = @kasSrv);
		if @UpdateLinks = 1 and @LinksExists = 1  exec sys.sp_dropserver @kasSrv, NULL;	----'droplogins';
		select @cnt = (select count(rtrim(data_source)) from sys.servers where data_source = @kasSrv);
		--set @kasSrv = quotename(ltrim(@kasSrv));
		set @kasSrv = 'N'''+@kasSrv +'''';
		IF @cnt = 0
		begin try
		begin transaction CreateLinkedServer
			exec master.dbo.sp_addlinkedserver	@server=@kasSrv, @srvproduct = N'SQL Server';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'collation compatible', @optvalue=N'false';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'data access', @optvalue=N'true';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'dist', @optvalue=N'false';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'pub', @optvalue=N'false';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'rpc', @optvalue=N'true';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'rpc out', @optvalue=N'true';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'sub', @optvalue=N'false';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'connect timeout', @optvalue=N'5';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'collation name', @optvalue=null;
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'lazy schema validation', @optvalue=N'false';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'query timeout', @optvalue=N'600';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'use remote collation', @optvalue=N'true';
			exec master.dbo.sp_serveroption		@server=@kasSrv, @optname=N'remote proc transaction promotion', @optvalue=N'true';
			exec master.dbo.sp_addlinkedsrvlogin @rmtsrvname=@kasSrv,@useself=N'False',@locallogin=NULL,@rmtuser=N'sa',@rmtpassword=N'korona321';
			exec ephemera.dbo.sp_addlinkedsrvlogin @rmtsrvname=@kasSrv,@useself=N'False',@locallogin=N'himera',@rmtuser=N'sa',@rmtpassword=N'korona321';

			--exec master.dbo.sp_addlinkedsrvlogin @rmtsrvname = @kasSrv, @locallogin = N'7r\dvg', @useself = N'False', @rmtuser = N'sa', @rmtpassword = N'korona321';
			--exec(' CREATE LOGIN himera WITH PASSWORD = ''lkjsf12_AEFxsx}.>''') AT @kasSrv;

			begin try
			begin transaction LinkTest				
				exec @retval = sp_testlinkedserver @servername = @kasSrv;
				commit transaction LinkTest;
			end try
			begin catch
				rollback transaction LinkTest;
				print char(13) + @kasSrv +' LinkTest failed with ErrCode = '+ @retval;
			end catch;

			commit transaction CreateLinkedServer;
		end try
		begin catch
			rollback transaction CreateLinkedServer;
			print char(13) + @kasSrv +' Trouble linked with ErrCode = '+ @retval;
		end catch;
		--ELSE
			--print 'LINK on '+ @kasSrv +' already exists';

		--+ N'DBCC CHECKDB (' + @kasFullName + N')' + N'WITH PHYSICAL_ONLY';
		--print N'CHECKING DATABASE '+ @kasFullName;
		--set @stringSQL = N'USE ' + @kasDb  + char(13) 
		--set @stringSQL = N'USE ' + '[KASSRV007\SQLNET007].[CashDB007]'  + char(13)

		set @stringSQL3 = N'insert into BON_COMMON(cashcode, shift, date_beg, time_beg, date_end, time_end, code, name, pricei, bquant, sumn, store)
								SELECT
									CC.CASHCODE,
									CC.SHIFT,
									CC.DATE_BEG,
									CC.TIME_BEG,
									CC.DATE_END,
									CC.TIME_END,
									CT.CODE,
									CT.NAME,
									CT.PRICEI,
									CT.BQUANT,
									CT.SUMN,
									'''+ @store +'''
								FROM ' + @kasFullName + '.[dbo].[CC] as cc with (nolock)
								LEFT JOIN ' + @kasFullName + '.[dbo].[CT] as CT with (nolock) ON CC.UNIQ = CT.UNIQ and CC.CHECKNUM = CT.CHECKNUM
								WHERE CC.DATE_BEG = CONVERT(date, GETDATE())
								and not exists (select 1 from BON_COMMON as b with (nolock) where b.cashcode = CC.CASHCODE
																							and b.date_beg = CC.DATE_BEG and b.time_beg = CC.TIME_BEG)
								;';
			begin try
				begin transaction @kasDb
					exec sp_executesql @stringSQL3;
					--set @stringSQL4 = '(select @@version) at '+ @KasSrv;

					commit transaction @kasDb;
					print  @kasSrv +' BON_COMMON commit'+  char(13);
					set @reflect = 1;
			end try
			begin catch
				rollback transaction @kasDb;
				print  @kasSrv +' BON_COMMON rollback'+  char(13);
				set @reflect = 0;
				--print @stringSQL4; --return;	
			end catch;
		--====================================================================================================================================
		--print 'Loading data to cube datawarehouse...';

		if @reflect = 1 begin try
			begin transaction tr1

				insert into GOODS(code, name, name_code) select bd.name, bd.code, null
															from	BON_COMMON bd
															where not exists (select 1 from GOODS g where bd.bc_id = g.goods_id);
				-- dimension table "Кассы"
				insert into CASHMACHINE(cashcode, shift)    select	'POS' + RIGHT('000'+ convert(varchar, B.CASHCODE), 3), 
																	'Смена' + RIGHT('000000' + convert(varchar, B.SHIFT), 6) 
															from	BON_COMMON b
															where not exists (select 1 from CASHMACHINE c where b.bc_id = c.cm_id);
				-- fact table for COMMON-scheme
				insert into SALES_COMMON(fkey, fkeyE, duration, cm_id, store_id, goods_id, pricei, bquant, sumn) select
							(convert(int, substring(convert(varchar, b.time_beg, 114), 1, 2))*100 +
							convert(int, substring(convert(varchar, b.time_beg, 114), 4, 2)))*100 +
							convert(int, substring(convert(varchar, b.time_beg, 114), 7, 2)),
							(convert(int, substring(convert(varchar, b.time_end, 114), 1, 2))*100 +
							convert(int, substring(convert(varchar, b.time_end, 114), 4, 2)))*100 +
							convert(int, substring(convert(varchar, b.time_end, 114), 7, 2)),
							convert(int, datediff(ss, b.time_beg, b.time_end)), 
							b.bc_id, b.store, b.bc_id, b.pricei, b.bquant, b.sumn 
							from BON_COMMON b
							where not exists (select 1 from SALES_COMMON s where b.bc_id = s.sc_id);

			commit transaction tr1;
			print  @kasSrv +' DWH commit'+  char(13);
		end try
		begin catch
			rollback transaction tr1;
			print  @kasSrv +' DWH rollback'+  char(13);
			--print char(13) +' 30 '+ char(13);
		end catch;

		--print convert(varchar, @kasSrv) +' is processed';
		FETCH NEXT FROM @CURSOR INTO @store, @kasSrv, @kasDb
	END
	CLOSE @CURSOR
END
GO
