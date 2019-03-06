/* Пример отчета из КИС NS2000. Язык ABL (Progress) */
/* Новый алгоритм электронной заявки поставщику с поставкой на Семью-Логистику. На алкогольную продукцию с новой формулой Автор - Кожевников Э.В.
   За основу взять отчет zaylog17.p
     Автор: Рогожников Д.А. 03.07.2017
 Изменение: Рогожников Д.А. 03.07.2017 
            ОТМЕНИЛИ 30.05.2018 - Поздеев С.В. 21.05.2018 Проверка ПТЗ(tmp1.tovzap) по КОНКРЕТНОЙ фирме в tmp-tov-zap.gds-ost если НЕТ удаляем
*/

{ beg-rep.i }

{ _tmp_vin.def }

{ global.i }
define variable previousPeriodStart as date no-undo.
define variable previousPeriodEnd as date no-undo.
/* Реализация за прошедший период */
define new shared temp-table tmp-sales
  field firm-code as integer
  field gds-code as integer
  field cond-rem-upd as decimal
index ind1 is primary firm-code gds-code .
/* используется в fnd610.p */
define new shared temp-table zay610
  field firm-code      as integer
  field cli-code       as integer /* поставщик по заявке */
  field cli-payee-code as integer init 0 /* поставщик Семьи-Логистика invoice.cli-payee-code */
  field way-bill       as character init "" /* направление(класс) из invoice.way-bill */
  field codeRC         as integer /* код склада РЦ */ 
  field inv-date       as date
  field week-dayz      as character extent 7 /* дни недели и час заказа */
  field inv-rec        as recid
index ind1 is primary firm-code cli-code cli-payee-code way-bill codeRC
.
define new shared temp-table zay610p
  field firm-code      as integer
  field cli-code       as integer /* поставщик по заявке */
  field cli-payee-code as integer init 0 /* поставщик Семьи-Логистика invoice.cli-payee-code */
  field way-bill       as character init "" /* направление(класс) из invoice.way-bill */
  field codeRC         as integer /* код склада РЦ */ 
  field inv-date       as date
  field week-dayz      as character extent 7 /* дни недели поставка поставка */
  field inv-rec        as recid
index ind1 is primary firm-code cli-code cli-payee-code way-bill codeRC
.
define temp-table tmp-class11
  field gds-code   as integer
  field class-code as character
  field nameTZ     as character
  field locode     as character
.
define temp-table CliPayeeCode
  field cli-payee-code as integer
  field cli-name       as character
  field cli-sbst as decimal init 0
index ind1 is primary cli-payee-code
.
define temp-table ErrorPhrase
  field cli-payee-code as integer
  field locode as character
  field nameTZ as character
  field phrase as character
  field statuso as integer
index ind1 is primary cli-payee-code locode  
.
define variable inv-rec611 as recid no-undo init ?.
define variable t-cli-payee-name as character no-undo.
define variable CliErrorFlag as logical no-undo.
define variable NotThatDay as integer no-undo.
define variable NotThatDay2 as integer no-undo.
define variable t-cli-payee-code as integer no-undo. 
define variable t-class-code11   as character no-undo.
define variable t-codeRC as integer no-undo.
define variable i-inv as integer no-undo.
define variable t-clock as character no-undo.
define variable last-sbst as decimal decimals 4 no-undo.
define variable flagErr as logical no-undo.
define variable d1 as character no-undo.
define variable d2 as character no-undo.
define variable kk as integer no-undo.
define variable n_d1 as integer no-undo.
define variable n_d2 as integer no-undo.
define variable t-num-day as integer no-undo.
define variable weekday-i as integer no-undo.
define variable weekday-name as character no-undo.
define variable FlagErrorGraf as logical no-undo.
define variable i-cli-payee-code as integer no-undo.
define variable i-error-zay as integer no-undo.
define variable t-week-day as character no-undo.
define variable i-day      as integer no-undo.
define variable tmp-OK as logical no-undo .
define variable GodnDays as integer no-undo.
define variable GodnClock as integer no-undo.  
define variable Flag210 as logical no-undo.
define variable FlagException as logical no-undo.
/* ======================================================= */
define variable t_GLNfor546 as character no-undo.
define variable t-cli-name   as char no-undo.
FUNCTION classesIsMutuallyExclusive RETURNS LOGICAL () FORWARD.
FUNCTION getPreviousPeriodYear RETURNS INTEGER () FORWARD.
function isGoodFromSupplier RETURNS LOGICAL(INPUT goodCode AS INTEGER, INPUT clientCode AS INTEGER) FORWARD.
function roundUp RETURNS INTEGER(input x as decimal) FORWARD.

/* Товары ТОП1000 */
define temp-table top1000 no-undo
  field gds-code as integer
index ind1 is primary gds-code.

/* Все товары из 607 документа с периодом действия акции ВНЦ и т.д. */
define temp-table actions no-undo
  field gds-code as integer
  field cli-code as integer
  field way-bill as character /* список фирм в 607 док-те, которые участвуют в акции */
  field beg-date as date 
  field end-date as date 
index ind1 is primary gds-code beg-date end-date
index ind2            gds-code cli-code beg-date end-date
.
define variable FlagActions as logical NO-UNDO.
/* Таблица дней по которым считали реализацию */
define temp-table isp-date no-undo
  field gds-code  as integer
  field gds-date  as date  /* Дата */
  field real-date as date /* Дата для реального расчета */
index ind1 is primary gds-code gds-date
index ind2 gds-code real-date.

/* Времянка под товары, которые исключаем из заявки (при выборе в фильтре отчета Список товаров исключить) */
define temp-table gds-out no-undo
  field gds-code  as integer
index ind1 is primary gds-code.

define variable gl_date as date no-undo.
define variable t_date as date no-undo.
define variable frmname as character no-undo init "".
define variable FlagLink100 as logical no-undo init no.
define variable count_days            as integer no-undo.
define variable cli-code-flt          like clients.cli-code no-undo.
define variable cli-name-flt          like clients.cli-name no-undo.
define variable clstype               as integer no-undo init 11.
define variable nfirms                as integer no-undo init 0.
define variable t-inv-date            as date no-undo.
define variable nclass                as integer no-undo.
define variable flag_exist            as logical init yes no-undo.
define variable t_firm_name           as character no-undo.
define variable rec-point             as recid no-undo.
define variable cli-type-flt          as integer no-undo.
define variable nn                    as integer no-undo.
define variable last-bar              as decimal no-undo.
define variable last-bar-date         as date no-undo. /* Дата первой поставки, товара в акции(т.е. pay-date не 31.12.2049 или не ?) */
define variable t-bar-code            as char no-undo.
define variable t-class-code          as char no-undo.
define variable tip-postav            as integer no-undo init 30.  /* Тип классификатора Поставщики */
define variable t-st-code             as integer no-undo.
define variable t-num-code            as char no-undo.
define variable t-firmcode            as integer no-undo.
define variable firmcodeBackup        as integer no-undo.
define variable manyFirmsFormat        as logical init yes.
define variable t-adres      as char no-undo.
define variable GLN as char no-undo.
define variable i-goods      as integer no-undo.
define variable t-gds-name   as character no-undo.
define variable t-gds-code   as integer no-undo.
define variable ncli         as integer no-undo.
define variable main-cli-code-flt   like clients.cli-code no-undo.
define variable banGoodDateStart            as date no-undo.
define variable banGoodDateEnd              as date no-undo.
define variable goodInTransitCount         as decimal no-undo.
define variable t_inv_date as date no-undo.
define variable t_pay_date as date no-undo.
define variable ntov as integer no-undo.
define variable countLogisticRemains     as logical no-undo init yes. /* С учетом остатков по Логистике, s-zay12_.i */
define variable condRemain    as decimal no-undo.
define variable totalRemain   as decimal no-undo.
define variable ii            as integer no-undo.
define variable iarc   as logical no-undo.
define variable manufactorIsCorrect   as logical no-undo.
define variable chs_ as int no-undo.
define variable Flag216 as integer no-undo.
define variable Flag546 as integer no-undo init 0. /* 0 - по всем */
define variable DiscoStore as char no-undo.
define variable FamilyAtHomeStore as char no-undo.
define variable t_barcode102 like bar-code.bar-code no-undo.
define variable FindGraf_ as logical no-undo.
define variable searchByAlternativePeriod as logical.
define variable alternativePeriodOldBase as logical.
define variable FlagCli95 as logical no-undo.
define variable Raznaradka as logical format "Да/Нет" no-undo init no.
/* ---Выбор производителей брэнд -------------------------------------*/
define variable clstype15       as integer no-undo init 15.
define variable s-g-work-code   as character no-undo.
define variable s-g-work-name   as character no-undo.
define variable nwork           as integer no-undo.
define variable t_val           as character no-undo.
define variable t_firmcode      as integer no-undo.
define variable NotMatrica as logical format "Матричный/Нематричный" no-undo init yes.
/* Новые переменные 2017 */
/*
define variable KoefStrahZapas as decimal decimals 2 no-undo init 1.4.   /* Коэффициент страхового запаса */
*/
{ _defwf.i &new=new &wfile = w-f-work }   /* Для выбора производителей */
define temp-table w-f-work-1
  field sel-rid as recid.

  { _defwf.i &wfile = work-file-r-goods &new=new }
define temp-table work-file-r-goods-1 no-undo      /* Для копии */
  field sel-rid as recid.

/* Бонусная группа { classesListDuo.flt } */
{ _defwf.i &wfile = w-f-class-backup &new=new }
define variable class-code-duo like class.class-code no-undo init "".
define variable class-name-duo like class.class-name no-undo init "По всем".
define variable class-name-duo-backup like class.class-name no-undo .
{ _defwf.i &wfile = w-f-class-duo &new=new }
{ _defwf.i &wfile = w-f-class-duo-backup &new=new }
define temp-table w-f-class-duo-1 no-undo        
  field sel-rid as recid.

define temp-table TovarOst no-undo  /* Товары с остатками в Семье-Логистике */
  field gds-code      as integer
  field fact-rem-upd  as decimal
index ind1 is primary gds-code.

define variable allBonusGroupsChosen as logical no-undo.
define variable KakoeRC              as logical format "Бригадирская/Водопроводная" no-undo init yes.
define variable rc-type              as integer no-undo.
define variable Catalog-TipIn        as logical format "Да/Нет" no-undo init no.
define variable Catalog-TipOut       as logical format "Да/Нет" no-undo init no.
define variable Ok_flag              as logical no-undo.
define variable tovarPP              as char no-undo.
define variable tovarPP-i            as integer no-undo.
define variable FlagAlko             as logical no-undo.
define variable p-firmcode           as integer no-undo.
define variable p-number             as integer no-undo.

define variable t-skladam   as integer no-undo.
define variable txt-skladam as char no-undo.
define variable i-frm       as integer no-undo.
define variable FlagAvailableFormat as logical no-undo.
define variable FlagClient  as integer no-undo.
/* define variable firmcode111  as logical no-undo init yes. */
define variable firmcode111 as integer no-undo init 1 .
define variable firmname111 as character no-undo init "Семья-Логистика".
define variable firm_code111 as integer no-undo init 111.

define variable cli-code-psv          like clients.cli-code no-undo.
define variable cli-name-psv          like clients.cli-name no-undo.

define buffer invoice-zap  for invoice.
define buffer goods-99     for goods.
define buffer gdb-calc     for gdsbody.
define buffer prc-type-roz for prc-type.
define buffer link-buf     for link.
define buffer link102 for link.
define buffer link-line7 for link.

define stream fff .
define stream ggg .
define stream log-str .

define temp-table tmp-cli no-undo /* Временная для поставщиков */
  field cli-code    as integer
  field postav-tip  as integer
  field flag-client as integer  /* 2-поставщик возит через Семью-Логистику, 1-поставщик внешний */
index ind1 is primary cli-code.

define temp-table chosenFirms no-undo /* Временная для поставщиков */
  field firmRecId     as recid
index ind1 is primary firmRecId.

{ defsel wf-clients new }
define temp-table wf-clients-1 no-undo      /* Для копии */
  field sel-rid as recid.

{ _defwf.i &new=new &wfile = wf-firms }    /* Для выбора фирм */
define workfile wf-firms-1 no-undo         /* Для копии wf-firms */
  field sel-rid as recid.

{ _defwf.i &wfile = w-f-class &new=new }

define temp-table w-f-class-1 no-undo        /* Для копии work-file */
  field sel-rid as recid.
define temp-table w-f-class-2 no-undo        /* Для копии work-file */
  field sel-rid as recid.

define temp-table wf-code-class no-undo    /* Для class в привычном виде */
  field class-code as char.

define buffer link-europa for link.

{ zaylogLogs.i }

run startLogs.

find first sysconf no-lock no-error.

assign
  Raznaradka   = no
  clstype      = 11
  cli-code-flt = 0
  cli-name-flt = ""
  cli-code-psv = 0
  cli-name-psv = "".  

assign
  tovarPP   = "Только ПП"
  tovarPP-i = 1.

for each w-f-class:
  delete w-f-class.
end.

if usconf.s-g-class-code <> "" then do:
  find first class
       where class.archive    = false and
             class.class-code = usconf.s-g-class-code and
             class.type       = clstype
    use-index class-type-ind no-lock no-error.
  if available class then do:
    create w-f-class.
    w-f-class.sel-rid = recid(class).
  end.
  else do:
    usconf.s-g-class-name = "".
  end.
end.
else do:
  usconf.s-g-class-name = "".
end.

nfirms = 0.
for each wf-firms exclusive-lock:
  delete wf-firms.  
end.

nfirms = 0.
firmcode = 99.
if firmcode = 0 then do:
  frmname = "ВСЕ ФИРМЫ".
end.
else do:
  find first r-firms
       where r-firms.archive = no
         and r-firms.code    = firmcode
    no-lock no-error.
  if available r-firms then do:
    create wf-firms.
    wf-firms.sel-rid = recid(r-firms).
    nfirms = nfirms + 1.
    assign
      frmname  = r-firms.name
      firmname = r-firms.name.
  end.
end. 

/* Было до добавления фильтра по фирмам
firmcode = 99.
firmsSearch:
for each r-firms
   where r-firms.archive = no
     and r-firms.code <> 111
no-lock:
  * Фирмы-исключенные из отчета (например закрытые) *
  if r-firms.code = 507 or 
     r-firms.code = 520 or 
     r-firms.code = 216 or 
     r-firms.code = 527 or 
     r-firms.code = 502 or 
     r-firms.code = 530 or 
     r-firms.code = 552 or 
     r-firms.code = 509 or 
     r-firms.code = 559 or 
     r-firms.code = 540 or 
     r-firms.code >= 700 then do:
    next firmsSearch.
  end.
  find first csh-conf
       where csh-conf.archive   = no 
         and csh-conf.firm-code = r-firms.code
  use-index firm-code no-lock no-error.
  if (available csh-conf) then do:
    create wf-firms.
    wf-firms.sel-rid = recid(r-firms).
    nfirms = nfirms + 1.
  end.
end.
*/

for each wf-clients exclusive-lock :
  delete wf-clients.
end.

assign
  cli-code-flt = 0
  cli-name-flt = ""
  /* firmcode111  = yes */
  firmname111 = "Семья-Логистика"
  firmcode111 = 1
  firm_code111 = 111 .

if usconf.r-g-gds-code <> 0 then do:
  find first r-goods
       where r-goods.archive  = no
         and r-goods.gds-code = usconf.r-g-gds-code
    no-lock no-error.
  if available r-goods then do:
    t-gds-name = r-goods.gds-name.       

    find first work-file-r-goods 
         where work-file-r-goods.sel-rid = recid(r-goods)
      no-lock no-error .

    if not available work-file-r-goods then do:
      create work-file-r-goods.
      assign
        work-file-r-goods.sel-rid = recid(r-goods).
      ntov = 1.  
    end.
  end.  
end.

run prioritiesToFile.

weekday-i = weekday(today).
if weekday-i = 2 then weekday-name = "понедельник". else
if weekday-i = 3 then weekday-name = "вторник".     else
if weekday-i = 4 then weekday-name = "среда".       else
if weekday-i = 5 then weekday-name = "четверг".     else
if weekday-i = 6 then weekday-name = "пятница".     else
if weekday-i = 7 then weekday-name = "суббота".     else
if weekday-i = 1 then weekday-name = "воскресенье". 

form
  skip
  space(1) firmcode label "    Фирма"
    help "Введите код фирмы" frmname format "x(25)" no-label 

/*   space(1) firmcode111 format "Семья-Логистика/Большая Семья ОПТ" no-label 
  skip */
  space(1) firmname111 format "x(18)" no-label 
  skip

  space(1) cli-code-flt format "999999999" label "Поставщик"
    help "Введите код поставщика (F3 - Справочник)"
           cli-name-flt format "x(20)" no-label skip

  space(1) cli-code-psv format "999999999" label "Поставщик РЦ"
    help "Введите код поставщика РЦ (F3 - Справочник)"
           cli-name-psv format "x(20)" no-label skip

  space(1) s-g-work-code format "x(10)" label "Производитель  "
    help "Введите код производителя ( F3 - Справочник )"
           s-g-work-name no-label format "x(30)" skip
  space(1) class-code-duo format "x(10)" label "Бонусная группа"
    help "Введите код бонусной группы" class-name-duo no-label format "x(40)" skip  
  space(1) usconf.s-g-class-code format "x(10)" label "    Класс"
    help "Введите класса товара по 19 классификатору"
           usconf.s-g-class-name no-label format "x(40)" skip

  space(4) usconf.r-g-gds-code format "999999999" label "Товар "
    help "Введите код товара (F3 - Справочник)" t-gds-name format "x(40)" no-label skip

  space(1) tovarPP label "Прямые поставки" help "Введите ПРОБЕЛОМ Только ПП/Кроме ПП/Все товары" format "x(10)" skip

  space(1) usconf.m-p-from-date format "99/99/9999" label "Период продаж с"
    help "Введите дату начала периода"
           usconf.m-p-to-date format "99/99/9999" label "по"
    validate(input usconf.m-p-to-date > input usconf.m-p-from-date,
      "Дата конца периода должна быть больше даты начала" )           
    help "Введите дату окончания периода" "не включая" skip

  space(1) count_days format ">>9" label "Кол-во дней,на которое делаем заказ"
    help "Введите число дней на которое делается заказ" skip

  space(3) t-inv-date label "Дата поставки" format "99/99/9999"
    help "Введите дату, на которую делается заявка" 

  space(1) NotMatrica label "Ассортимент" 
    help "выбор пробелом" skip          

  space(3) KakoeRC label "РЦ" help "Введите ПРОБЕЛОМ РЦ, на которое оформлять заказ" 

  space(4) Raznaradka label "Разнарядка" help "Действует при заявке на внешнего поставщика"
  space(1) weekday-name format "x(11)" label "День заказа" help "Выбор пробелом" skip    
/*
  space(3) KoefStrahZapas label "Коэффициент страхового запаса" format "zz9.99" help "Введите коэффициент" skip
*/
  space(1) countLogisticRemains label "С учетом остатков Семьи-Логистики" format "Да/Нет" 
    help "Выберите ПРОБЕЛом Да/Нет" skip(0)
  space(1) Catalog-TipIn label "Список товаров включить"
    help "Выберите пробелом Да/Нет"
           Catalog-TipOut label "  Список товаров исключить"
    help "Выберите пробелом Да/Нет" skip
  space(1) previousPeriodStart format "99/99/9999" label "Период продаж №2 с"
    help "Введите дату начала периода №2"
      previousPeriodEnd format "99/99/9999" label "по"    
    help "Введите дату окончания периода №2" "не включая" skip    
with frame ask-fr side-labels title color value (flt-up) RepTitle
        color value(flt-up)
        prompt value(flt-pr)
        overlay centered row 3.

color display value (flt-ds)
  frmname
  cli-name-flt
  cli-name-psv
  class-name-duo
  usconf.s-g-class-name
with frame ask-fr.

color prompt value (flt-pr)
  firmcode
  /* firmcode111 */
  firmname111  
  cli-code-flt
  cli-code-psv
  s-g-work-name
  class-code-duo
  usconf.s-g-class-code
  usconf.r-g-gds-code
  tovarPP
  m-p-from-date
  m-p-to-date
  count_days
  t-inv-date
  NotMatrica
  KakoeRC
/*  KoefStrahZapas */
  weekday-name
  countLogisticRemains
  Catalog-TipIn
  Catalog-TipOut
  previousPeriodStart
  previousPeriodEnd    
with frame ask-fr.

form
  "Esc-Выход F2,F9-Формирование"
WITH FRAME footr row 22 width 80 no-box color value (sc-pr) overlay.
view frame footr.

form
  skip
  i-goods      format ">>>>>>>>9" label " Карточек" skip
  t-gds-code   format ">>>>>>>>9" label "    Товар" t-gds-name format "x(30)" no-label skip
with frame pro-fr side-labels overlay centered  row 13
    color value (prs-lb)
    title color value (prs-lb) " ФОРМИРОВАНИЕ ОТЧЕТА " 1 DOWN.

color display value (prs-ds)
  i-goods
  t-gds-code
  t-gds-name
with frame pro-fr.

form
  "Esc-Остановить отчет"
WITH FRAME footr-1 row 22 width 80 no-box color value (sc-pr) overlay.

/* Определим даты анализа продаж, за последний календарный месяц */
assign
  usconf.m-p-from-date = today - 30
  usconf.m-p-to-date   = today.

t-inv-date = today + 1.
count_days = 7.

cycle:
do while true:

  display cli-name-flt class-name-duo usconf.s-g-class-name t-gds-name with frame ask-fr.
  next-prompt firmcode  with frame ask-fr.

  do on endkey undo,next on error undo,next:
    update
      firmcode
      /* firmcode111 */
      firmname111  
      cli-code-flt
      cli-code-psv
      s-g-work-code
      /* class-code-duo when (sysnet = 1 or sysnet = 2) */
      class-code-duo
      usconf.s-g-class-code
      usconf.r-g-gds-code
      tovarPP
      m-p-from-date
      m-p-to-date
      count_days
      t-inv-date
      NotMatrica
      KakoeRC
      Raznaradka
      weekday-name
/*      KoefStrahZapas  */
      countLogisticRemains
      Catalog-TipIn
      Catalog-TipOut
      previousPeriodStart
      previousPeriodEnd        
      go-on (F3 F8 F9)
    with frame ask-fr
    FilterU:
    editing:

      {_readkey.i}

      if (keyfunction(lastkey_) = "GO") or (keyfunction(lastkey_) = "NEW-LINE") then do:
        ReportExist = yes.
        leave FilterU.
      end.

      if (keyfunction (lastkey_) = "RECALL") then do:
        next.
      end.

      if (keyfunction(lastkey_) = "CLEAR") then do:
        next FilterU.
      end.

      if keyfunction(lastkey_) = "END-ERROR" then do:
        ready = no.
        leave cycle.
      end.

      if lookup(keyfunction(lastkey_),"BACK-TAB, ,TAB,RETURN,END-ERROR,GO") = 0
      and (frame-field = "tovarPP" OR frame-field = "firmname111" OR frame-field = "weekday-name") then next.

      if lookup (keyfunction(lastkey_), "FIND, ,GO,RETURN,TAB,BACK-TAB" ) > 0 then do:
        if frame-field = "firmcode" and lookup( keyfunction(lastkey_),
          "TAB,FIND,RETURN" )  > 0 then
        do:
          if input firmcode = 0 and
             input firmcode <> "" and
             keyfunction(lastkey_) <> "FIND" then do:
              assign
                firmcode = 0
                frmname = "ВСЕ ФИРМЫ".
            display firmcode frmname with frame ask-fr.
            nfirms = 0.
            for each wf-firms:
              delete wf-firms.
            end.
          end.
          else do:
            if input firmcode <> "" or
               keyfunction(lastkey_) = "FIND" then do:

              assign firmcode.   /* Запомним что было введено с экрана */

              for each wf-firms-1:
                delete wf-firms-1.
              end.
              for each wf-firms:  /* Сохраним копию файла */
                create wf-firms-1.
                wf-firms-1.sel-rid = wf-firms.sel-rid.
              end.

              for each wf-firms:
                delete wf-firms.
              end.

              run r-frm00.p ( input frame ask-fr firmcode,
                keyfunction(lastkey_) = "FIND", output rec-point ).

              if keyfunction(lastkey) = "END-ERROR" then do: /* Вышли по ESC */
                nfirms = 0.
                for each wf-firms:
                  delete wf-firms.
                end.
                for each wf-firms-1: /* Восстановим фирмы, которые были до F3 */
                  create wf-firms.
                  wf-firms.sel-rid = wf-firms.sel-rid.
                  nfirms = nfirms + 1.
                end.
              end.

              find first wf-firms no-error .
              if available wf-firms then rec-point = wf-firms.sel-rid.
              find next wf-firms no-error .
              if available wf-firms then do:
                nfirms = 0.
                t_firm_name  = "".
                for each wf-firms:
                  find base.r-firms where recid(base.r-firms) = wf-firms.sel-rid no-lock no-error.
                  if available base.r-firms and base.r-firms.archive = no then
                    assign
                      nfirms = nfirms + 1
                      t_firm_name  = t_firm_name + string(base.r-firms.code) + ",".
                  else
                    delete wf-firms.
                end.
                lastkey_ = keycode(kblabel("RETURN")).
                assign
                  frmname = "Выбрано " + string(nfirms) + " (" + substring(t_firm_name,1,length(t_firm_name) - 1) + ")".
                display frmname @ frmname "" @ firmcode with frame ask-fr.

              end.
              else do:
                if rec-point <> ? then do:
                  find base.r-firms where recid(base.r-firms) = rec-point no-lock no-error.
                  if available base.r-firms then do:
                      assign
                        firmcode = base.r-firms.code
                        frmname  = base.r-firms.name.
                    lastkey_ = keycode(kblabel("RETURN")).
                    nfirms = 1.
                    find first wf-firms
                         where wf-firms.sel-rid = rec-point
                      no-lock no-error.
                    if not available wf-firms then do:
                      create wf-firms.
                      wf-firms.sel-rid = rec-point.
                    end.
                  end.
                  display firmcode frmname with frame ask-fr.
                end. /* if rec-point <> ? then do: */
                else
                  lastkey_ = - 1.
              end.
            end. /* if input firmcode <> "" or */
            if nfirms <> 0 then do:
              nfirms = 0.
              for each wf-firms:
                nfirms = nfirms + 1.
              end.
            end.
          end.
        end. /* firmcode */
        else
        if frame-field = "class-code-duo" then do:
          /* Механизм бэкапа нужен для устранения конфликта за w-f-class с списком выбора направления */
          for each w-f-class-backup exclusive-lock:
            delete w-f-class-backup.
          end.
          for each w-f-class exclusive-lock:
            create w-f-class-backup.
            assign w-f-class-backup.sel-rid = w-f-class.sel-rid.
            delete w-f-class.
          end.
          { classesListDuo.flt &classType = 87 } /* Результат в w-f-class-duo */
          for each w-f-class-backup no-lock:
            create w-f-class.
            assign w-f-class.sel-rid = w-f-class-backup.sel-rid.
          end.
        end.      
        else
        if frame-field = "KakoeRC" then do:
          if keyfunction ( lastkey_ ) = " " then do:
            assign KakoeRC = not KakoeRC.
            display KakoeRC with frame ask-fr.
            lastkey_ = -1.
          end.
        end.        
        else
        if frame-field = "Raznaradka" then do:
          if keyfunction ( lastkey_ ) = " " then do:
            assign Raznaradka = not Raznaradka.
            display Raznaradka with frame ask-fr.
            lastkey_ = -1.
          end.
        end.        
        else
        if frame-field = "weekday-name" then do:
          if keyfunction ( lastkey_ ) = " " then do:
            if weekday-name = "понедельник" then assign weekday-name = "вторник"     weekday-i = 3. else
            if weekday-name = "вторник"     then assign weekday-name = "среда"       weekday-i = 4. else 
            if weekday-name = "среда"       then assign weekday-name = "четверг"     weekday-i = 5. else 
            if weekday-name = "четверг"     then assign weekday-name = "пятница"     weekday-i = 6. else 
            if weekday-name = "пятница"     then assign weekday-name = "суббота"     weekday-i = 7. else 
            if weekday-name = "суббота"     then assign weekday-name = "воскресенье" weekday-i = 1. else 
            if weekday-name = "воскресенье" then assign weekday-name = "понедельник" weekday-i = 2.

            display weekday-name with frame ask-fr.
            lastkey_ = -1.
          end.
        end. 
        else
        if frame-field = "NotMatrica" then do:
          if keyfunction ( lastkey_ ) = " " then do:
            assign NotMatrica = not NotMatrica.
            display NotMatrica with frame ask-fr.
            lastkey_ = -1.
          end.
        end.           
        else
        if frame-field = "firmname111" then do:
          if keyfunction ( lastkey_ ) = " " then do:
            if firmcode111 = 1 then assign firmname111 = "Большая Семья ОПТ".  else 
            if firmcode111 = 2 then assign firmname111 = "Семья ОПТ".  else 
            firmname111 = "Семья-Логистика".
            firmcode111 = firmcode111 + 1.
            if firmcode111 > 3 then firmcode111 = 1.
            display firmname111 with frame ask-fr.
            lastkey_ = -1.
          end.
        end.                                     
/*         else
        if frame-field = "firmcode111" then do:
          if keyfunction ( lastkey_ ) = " " then do:
            assign firmcode111 = not firmcode111.
            display firmcode111 with frame ask-fr.
            if firmcode111 then
              firm_code111 = 111. else
              firm_code111 = 600.
            lastkey_ = -1.
          end.
        end.                         */
        else
        if frame-field = "Catalog-TipIn" then do:
          if keyfunction ( lastkey_ ) = " " then do:
            assign Catalog-TipIn = not Catalog-TipIn.
            display Catalog-TipIn with frame ask-fr.
            lastkey_ = -1.
          end.
        end.
        else
        if frame-field = "Catalog-TipOut" then do:
          if keyfunction ( lastkey_ ) = " " then do:
            assign Catalog-TipOut = not Catalog-TipOut.
            display Catalog-TipOut with frame ask-fr.
            lastkey_ = -1.
          end.
        end.
        else
        if frame-field = "countLogisticRemains" then do:
          if keyfunction ( lastkey_ ) = " " then do:
            assign countLogisticRemains = not countLogisticRemains.
            display countLogisticRemains with frame ask-fr.
            lastkey_ = -1.
          end.
        end.
        else
        if frame-field = "tovarPP" then do:
          if keyfunction ( lastkey_ ) = " " then do:
            if tovarPP-i = 1 then tovarPP = "Кроме ПП". else
            if tovarPP-i = 2 then tovarPP = "Все товары". else
            tovarPP = "Только ПП".

            tovarPP-i = tovarPP-i + 1.
            if tovarPP-i > 3 then 
              tovarPP-i = 1.
            display tovarPP with frame ask-fr.
            lastkey_ = -1.
          end.
        end.
        else
        if frame-field = "cli-code-psv" AND lookup( keyfunction(lastkey_), "RETURN,TAB,FIND") <> 0 then do:
          assign cli-code-psv.
          if input cli-code-psv = 0 and keyfunction ( lastkey_ ) <> "FIND" then do:
            assign cli-name-psv = "". 
            display cli-code-psv cli-name-psv with frame ask-fr.
          end.          
          else do:
            if input cli-code-psv <> "" or keyfunction(lastkey_) = "FIND" then do:            
              assign cli-code-psv.

              for each wf-clients-1 exclusive-lock:
                delete wf-clients-1.
              end.

              for each wf-clients no-lock:
                find first wf-clients-1
                  where wf-clients-1.sel-rid = wf-clients.sel-rid
                  no-lock no-error.
                if available wf-clients-1 then next.
                create wf-clients-1.
                assign wf-clients-1.sel-rid = wf-clients.sel-rid.
              end.

              cli-type-flt = 1.
              run r-orscli.p ( input-output cli-type-flt, cli-code-flt,
                                keyfunction (lastkey_) = "FIND",
                                output rec-point, "1" ).              
              if rec-point = ? then next.
              find clients where RECID (clients) = rec-point no-lock no-error.
              if not available clients then next.
              ASSIGN
                cli-code-psv = clients.cli-code
                cli-name-psv = clients.cli-name
              .        
              for each wf-clients exclusive-lock:
                delete wf-clients.
              end.

              for each wf-clients-1 no-lock:
                find first wf-clients
                  where wf-clients.sel-rid = wf-clients-1.sel-rid
                  no-lock no-error.
                if available wf-clients then next.
                create wf-clients.
                assign wf-clients.sel-rid = wf-clients-1.sel-rid.
              end.              
            end.
          end. 
          display cli-code-psv cli-name-psv with frame ask-fr.          
        end.

         /* Поставщик */
        { _clicode.flt }
        /* Класс */
        { _clas2_.flt }
        /* Товары */
        { _rgoods_.flt } /* work-file-r-goods */
        /* Фирмы */
        /* { frm-rep.flt }  */
        /* производитель */
        { claswork.flt "ВСЕ ПРОИЗВОДИТЕЛИ" clstype15 }

        if keyfunction (lastkey_) = "FIND" then lastkey_ =  keycode(kblabel("RETURN")).
      end. /* lookup find,go ... */

      if lastkey_ <> -1 then apply lastkey_.
      if go-pending then next FilterU.
    end. /* editing */
  end. 

  firmcodeBackup = firmcode.

  if firmcode111 = 1 then 
    firm_code111 = 111 . else
  if firmcode111 = 2 then 
    firm_code111 = 600 . else
  firm_code111 = 605 .

  if count_days = 0 then do:
    run _warn.p("Не указано кол-во дней, на которое делаем заказ!").
    next cycle.
  end.

  if previousPeriodEnd - previousPeriodStart <= 0 then do:
    run _warn.p ("Дата конца периода должна быть больше даты начала!").
    next cycle .
  end.

  if Catalog-TipIn and Catalog-TipOut then do:
    run _warn.p("Нельзя выбирать в списке товаров одновременно Включить и Исключить!").
    next cycle.
  end.

  for each gds-out exclusive-lock:
    delete gds-out.
  end.
    
  if (cli-code-flt = 111 OR cli-code-flt = 600 OR cli-code-flt = 605) AND cli-code-psv <> 0 then do: 
    /* если Задан поставщик РЦ, берем как список товаров ассортимент заданного поставщика */
    run SearchForAssortment.
    find first work-file-r-goods no-lock no-error.
    if not available work-file-r-goods then do:
      run _warn.p("Нет данных по выбранному поставщику РЦ!").
      next cycle.      
    end.
  end.
  else do:
    if Catalog-TipIn or Catalog-TipOut then do:
      Ok_flag = no.
      run exp_sps.p (input-output Ok_flag). 
      if NOT Ok_flag then do:
        run _warn.p("Список товаров пустой!").
        next cycle.      
      end.
      
      if Catalog-TipOut then do:
        for each work-file-r-goods exclusive-lock:
          find first r-goods
               where recid(r-goods) = work-file-r-goods.sel-rid
            no-lock no-error.
          if available r-goods then do:
            find first gds-out
                 where gds-out.gds-code = r-goods.gds-code
              no-lock no-error.
            if not available gds-out then do:
              create gds-out.
              assign gds-out.gds-code = r-goods.gds-code.
            end.     
          end.     
          delete work-file-r-goods.
        end.
      end.
    end.
  end.

  if cli-code-flt <> 0 then do:
    find first clients
         where clients.archive  = no
           and clients.cli-code = cli-code-flt
      no-lock no-error.
    if not available clients then do:
      run _warn.p("Не найден поставщик с кодом: " + string(cli-code-flt,">>>>>>>>9")).
      next cycle.
    end.
  end.

  for each tmp-cli exclusive-lock:
    delete tmp-cli.
  end.
  ncli = 0.

  find first wf-clients no-lock no-error.
  if available wf-clients then do:
    for each wf-clients no-lock:
      find first clients
           where recid(clients) = wf-clients.sel-rid
        no-lock no-error.
      if available clients then do:
        ncli = ncli + 1.
        create tmp-cli.
        assign
          tmp-cli.cli-code = clients.cli-code.
        
        find first link
             where link.archive    = no
               and link.file-name  = "clients"
               and link.object-net = clients.clients-net
               and link.object-num = clients.clients-num
               and link.type       = tip-postav
          use-index object-net-num no-lock no-error.
        if available link then do:
          if link.class-code = "3" or link.class-code = "4" then
            t-st-code = 98. else  
            t-st-code = 99.
        end.
        else
          t-st-code = 99.

        assign
          tmp-cli.postav-tip = t-st-code.
      
        /* Нужно дополнительно проверить поставщика, надо четко понимать это внешний поставщик или поставщик, который возит на Семью-Логистику */
        FlagClient = 0.
        if tmp-cli.cli-code <> firm_code111 /* 111 */ then do:
          FlagClient = 1.  /* По-умолчанию ставим тип 1 - поставщик внешний */

          find first invoice
               where invoice.storno    = no
                 and invoice.firm-code = firm_code111 /* 111 */
                 and invoice.st-cli-type = 3
                 and invoice.st-code   = 99
                 and invoice.cond-fact = "фак"
                 and invoice.cli-type  = 1
                 and invoice.cli-code  = tmp-cli.cli-code
                 and invoice.inv-date <= today
            use-index inv-cli no-lock no-error.
          if available invoice then do:
            /* Поняли, что поставщик работает с Семьей-Логистикой. Теперь поймем, работает ли поставщик напрямую с магазинами */
            release invoice.
            find first invoice
                 where invoice.storno    = no
                   and invoice.firm-code = 99
                   and invoice.st-cli-type = 3
                   and invoice.st-code   = 99
                   and invoice.cond-fact = "фак"
                   and invoice.cli-type  = 1
                   and invoice.cli-code  = tmp-cli.cli-code
                   and invoice.inv-date <= today
                   and invoice.gd-type-code = 567
              use-index inv-cli no-lock no-error.
            if not available invoice then do:
              FlagClient = 2.  /* тип 2 - поставщик возит только на Семью-Логистику */
              if firm_code111 = 111 then
                FlagClient = 111. 
              else
              if firm_code111 = 605 then
                FlagClient = 605. 
              else              
                FlagClient = 600.              
            end.
            else do:
              /* А тут ситуация когда поставщик возит и на Логистику и напрямую в магазины. Спрашиваем какого поставщика нам надо. */
              find first clients
                   where clients.archive  = no
                     and clients.cli-code = tmp-cli.cli-code
                no-lock no-error.
              if available clients then do:
                ans = yes.
                run _ask.p(input-output ans, "Формировать заказ поставщику " + trim(clients.cli-name) + " через РЦ?").
                if ans then do:
                  FlagClient = 2.  /* тип 2 - поставщик возит только на Семью-Логистику */
                  if firm_code111 = 111 then
                    FlagClient = 111. 
                  else
                  if firm_code111 = 605 then
                    FlagClient = 605. 
                  else                  
                    FlagClient = 600.                               
                end.
              end.
            end.  
          end.
        end.
        assign
          tmp-cli.flag-client = FlagClient.

      end.
    end.
  end.

  find first tmp-cli no-lock no-error.
  if not available tmp-cli then do:
    run _warn.p("Не выбран поставщик!").
    next cycle.
  end.

  for each TovarOst exclusive-lock:
    delete TovarOst.
  end.  

  t-st-code = 99.

  searchByAlternativePeriod = no.
  if (previousPeriodStart <> ? and previousPeriodEnd <> ?) then do:
      searchByAlternativePeriod = yes.
  end.

  alternativePeriodOldBase = no.
  if ((searchByAlternativePeriod = yes) and (YEAR(previousPeriodStart) = getPreviousPeriodYear())) then do:
    alternativePeriodOldBase = yes.
  end.

  if (searchByAlternativePeriod = yes and alternativePeriodOldBase = yes) then do:
    run conctOld.p.
    if (not connected("base-old")) then do:
      run _warn.p("Не получается подключиться к базе прошлого года!").
      next cycle.
    end.
  end.

  if t-inv-date = ? then do:
    run _warn.p("Введите дату поставки!").
    next cycle.
  end.

  if t-inv-date < today then do:
    run _warn.p("Нельзя выбрать дату поставки ранее текущей даты!").
    next cycle.
  end.

  /* определим список фирм */
  nn = 0.
  for each tmp-firms exclusive-lock:
    delete tmp-firms.
  end.

  for each chosenFirms:
    delete chosenFirms.
  end.

  find first r-firms where r-firms.archive = no and
                           r-firms.code = firmcode
                           use-index r-firms-arj no-lock no-error.
  if not available r-firms then do:
    run _warn.p("Не найдена фирма " + string(firmcode) + " !").
    next cycle.
  end.

  if (cli-code-flt = firm_code111) then do:
    if (classesIsMutuallyExclusive()) then do:
      run _warn.p("Поставщику Семья-Логистика на алкоголь и пиво необходимо формировать отдельную заявку!").
      next cycle.
    end.
  end.

  FindGraf_ = no. /* yes - проверяем графики */
  run fillChosenFirms(INPUT firmcode, INPUT TABLE wf-firms, INPUT-OUTPUT TABLE chosenFirms, OUTPUT manyFirmsFormat).
  if firmcode = 99 AND FindGraf_ then do:
    find first chosenFirms no-lock no-error.
    if NOT available chosenFirms then do:
      /* run _warn.p("На текущий день " + string(today,"99.99.9999") + " по графику нет заказов ни по одному магазину"). */
      run _warn.p("На день заказа: " + trim(weekday-name) + " по графику нет заказов ни по одному магазину").
      next cycle.      
    end.
  end.

  /* ================================================================== */
  for each chosenFirms no-lock:
    find first r-firms where r-firms.archive = no and
                             recid(r-firms) = chosenFirms.firmRecId
                             no-lock no-error.
    if (available r-firms) then do:
      find first tmp-firms
           where tmp-firms.firm-code = r-firms.code
        no-lock no-error.
      if NOT available tmp-firms then do:
        find first sign /* Определим тип классификатора поставщиков */
             where sign.archive      = no
               and sign.file-code    = 33
               and sign.sg-owner-net = r-firms.r-firms-net
               and sign.sg-owner-num = r-firms.r-firms-num
               and sign.sg-code      = 168
          no-lock no-error.
        if available sign then do:
          tip-postav = INT(sign.val) no-error.
        end.
        if tip-postav = ? or tip-postav = 0 then
          tip-postav = 30.      

        /* Проверка на алкогольную лицензию. 10.07.17 по запросу Зебзеевой О. */
        run AlkoLicen(input r-firms.cli-code, output FlagAlko).

        if r-firms.code = 546 then do: /* 888 здесь добавим нашу обработку складов 546 фирмы 16.12.2015 */
          if Flag546 = 0 then do: /* конкретный магазин Семьи у дома не выбран, тогда все */
            for each r-store 
              where r-store.archive = no
                and r-store.firm-code = r-firms.code
              no-lock:
              find first sign /* ищем GLN */
                   where sign.archive      = no
                     and sign.file-code    = 075
                     and sign.sg-owner-net = r-store.r-store-net
                     and sign.sg-owner-num = r-store.r-store-num
                     and sign.sg-code      = 250
                use-index list-ind no-lock no-error.
              if NOT available sign then next. /* только склады с GLN */
              create tmp-firms.    
              assign
              tmp-firms.firm-name = r-firms.name + "(" + trim(r-store.cli-name) + ")"
              tmp-firms.firm-code = r-firms.code
              tmp-firms.disco     = ""
              tmp-firms.postav-tip = tip-postav
              tmp-firms.alkolic   = FlagAlko
              tmp-firms.GLN = trim(sign.val)
              tmp-firms.nearHome = string(r-store.cli-code). /* 1 - Вагонная, 2 - Холмогорская и т.д. */
              if length(STRING(tmp-firms.nearHome)) = 1 then 
                tmp-firms.Code546 = int(tmp-firms.nearHome) * 100000 + r-firms.code.
              else
              if length(STRING(tmp-firms.nearHome)) = 2 then  
                tmp-firms.Code546 = int(tmp-firms.nearHome) * 10000 + r-firms.code.
              nn = nn + 1.
            end.
          end. 
          else do:
            create tmp-firms.
            assign
            tmp-firms.firm-name  = r-firms.name 
            tmp-firms.firm-code  = r-firms.code
            tmp-firms.disco      = ""            
            tmp-firms.nearHome   = STRING(Flag546)
            tmp-firms.alkolic    = FlagAlko
            tmp-firms.GLN        = t_GLNfor546
            tmp-firms.postav-tip = tip-postav.
            if length(STRING(tmp-firms.nearHome)) = 1 then 
              tmp-firms.Code546 = int(tmp-firms.nearHome) * 100000 + r-firms.code.
            else
            if length(STRING(tmp-firms.nearHome)) = 2 then  
              tmp-firms.Code546 = int(tmp-firms.nearHome) * 10000 + r-firms.code.
            nn = nn + 1.
          end.
        end.
        else do:
          create tmp-firms.
          assign
            tmp-firms.firm-name = r-firms.name
            tmp-firms.firm-code = r-firms.code
            tmp-firms.disco     = ""
            tmp-firms.alkolic   = FlagAlko
            tmp-firms.GLN       = ""
            tmp-firms.Code546   = 0
            tmp-firms.postav-tip = tip-postav.
          if r-firms.code = 216 then
            tmp-firms.disco = "1".  

          nn = nn + 1.
          if r-firms.code = 216 then do:
            create tmp-firms.
            assign
            tmp-firms.firm-name = r-firms.name
            tmp-firms.firm-code = r-firms.code
            tmp-firms.disco     = "2" /* Мира 103 */ 
            tmp-firms.postav-tip = tip-postav.
          end.
        end.
      end.
    end.
  end.

  if nn = 0 then do:
    run _warn.p("Не выбрана фирма!" ).
    next cycle.
  end.

  /* Обработка приоритетов */
  priority-cikl:
  for each class
     where class.type    = 97
       and class.archive = no
    no-lock:
          
    p-firmcode = INT(substring(class.class-code,3)) no-error.
    if p-firmcode = ? then p-firmcode = 0.

    p-number = INT(substring(class.class-code,1,2)) no-error.
    if p-number = ? then p-number = 0.

    find first tmp-firms
         where tmp-firms.firm-code = p-firmcode
      exclusive-lock no-error.
    if available tmp-firms then do:
      assign
        tmp-firms.priority = p-number.
    end.     
  end.  
  
  /* Т.к. в списке приоритетов не все фирмы, проставим для таких фирм номер искусственно */
  p-number = 1000.
  for each tmp-firms exclusive-lock
     where tmp-firms.priority = 0
        by tmp-firms.firm-code:

    assign
      tmp-firms.priority = p-number.
    p-number = p-number + 1.
  end.

  for each wf-code-class exclusive-lock:
    delete wf-code-class.
  end.

  hide message no-pause.
  message "Подождите... Очищаем базу отчетов".

  find first tmp1 no-lock no-error.
  if available tmp1 then do:
    for each tmp1 exclusive-lock:
      delete tmp1.
    end.
  end.
  release tmp1.
  find first tmp1 no-lock no-error.
  if available tmp1 then flag_exist = yes.
                    else flag_exist = no.

  for each tmp2 exclusive-lock:
    delete tmp2.
  end.

  for each tmp-sales exclusive-lock:
    delete tmp-sales.
  end.

  for each tmp-gds-cli exclusive-lock:
    delete tmp-gds-cli.
  end.

  hide message no-pause.

  ready = yes.
  if flag_exist then do:
    run _warn.p("Технический сбой. Перезагрузите окно NS2000!").
    return.
  end.

  /* На случай если отчет был запущен до перехода по всем полям */
  /* Установка направлений (класс 2) */
  find first w-f-class-duo no-lock no-error.
  if (not available w-f-class-duo) then do:
    if class-code-duo = "" then do:
      for each class 
         where class.type = 87
           and class.archive = no 
      no-lock:
        create w-f-class-duo.
        assign w-f-class-duo.sel-rid = recid(class).
      end.
    end.
    else do:
      find first class
           where class.type = 87
             and class.archive = no 
             and class.class-code = class-code-duo
      no-lock no-error.
      if (available class) then do:
        create w-f-class-duo.
        assign w-f-class-duo.sel-rid = recid(class).
      end.
    end.
  end.
  if (class-name-duo = "По всем") then 
    allBonusGroupsChosen = yes. else 
    allBonusGroupsChosen = no.

  /* Проверка на дублирование записей по классам */
  nclass = 0.
  for each w-f-class-1 exclusive-lock:
    delete w-f-class-1.
  end.
  for each w-f-class exclusive-lock:
    find first w-f-class-1
      where w-f-class-1.sel-rid = w-f-class.sel-rid
      no-lock no-error.
    if available w-f-class-1 then do:
      delete w-f-class.
    end.
    else do:
      find first class
           where recid(class) = w-f-class.sel-rid
        no-lock no-error.   
      if available class then do:
        find first wf-code-class
             where wf-code-class.class-code = class.class-code
          no-lock no-error.
        if not available wf-code-class then do:
          nclass = nclass + 1.
          create wf-code-class.
          assign
            wf-code-class.class-code = class.class-code.
          create w-f-class-1.
          w-f-class-1.sel-rid = w-f-class.sel-rid.
        end.
      end.
    end.
  end.
  
  /* Поиск графиков поставки 610 ======================== */
  for each zay610 exclusive-lock:
    delete zay610.
  end.  
  for each zay610p exclusive-lock:
    delete zay610p.
  end.    
/*  if manyFirmsFormat = no then do: НЕ централизованная заявка */
    for each chosenFirms no-lock:
      find first r-firms
        where recid(r-firms) = chosenFirms.firmRecId
        no-lock no-error.
      if NOT available r-firms then next.
      for each tmp-cli no-lock:
        run fnd610.p (today,
                      r-firms.code,
                      tmp-cli.cli-code).
      end.
    end.
  /* end. */

  /* message "Централизованная заявка "   manyFirmsFormat. pause. */
  if manyFirmsFormat then do:
    run FindInv607.   /* Поиск прошедших акций в разрезе товаров */
  end.

  /* Поиск привязки фирм к АМ и поиск самих товаров в АМ */
  run poisk_am.

  find first prc-type-roz
       where prc-type-roz.archive = no
         and prc-type-roz.code    = 1
    no-lock no-error.

  /* 13.02.17 RDA С учетом остатков Семьи-Логистики сбор времянки */
  /* psv1970 Работают ли в сети с таблицей logost */
  define variable FlagLogOst as logical no-undo.
  FlagLogOst = no.
  find first r-net
    where r-net.archive = no
      and r-net.net     = sysnet
    no-lock no-error.
  if available r-net then do:
    find first sign
         where sign.archive      = no
           and sign.file-code    = 36
           and sign.sg-owner-net = r-net.r-net-net
           and sign.sg-owner-num = r-net.r-net-num
           and sign.sg-code      = 330
      no-lock no-error.  
    if available sign then do:
      FlagLogOst = yes.
    end.
  end.    

  if (countLogisticRemains = true) and (nclass > 0) then do:
    for each wf-code-class no-lock:
      lnk-cikl:
      for each link
         where (link.class-code begins wf-code-class.class-code)
           and link.type      = clstype
           and link.file-name = "r-goods"
           and link.archive   = no
        use-index file-class-ind no-lock:

        find first r-goods
             where r-goods.r-goods-net = link.object-net
               and r-goods.r-goods-num = link.object-num
          no-lock no-error.
        if not available r-goods then next lnk-cikl.
        if r-goods.archive = yes then next lnk-cikl.

        totalRemain = 0.
        /* Поиск товаров на складах psv1970 */
        if FlagLogOst AND firm_code111 = 111 then do:
          run ost-logost.p (input r-goods.gds-code, 
                            input t-inv-date, 
                            input "fact-rem", 
                            input-output totalRemain).
        end.
        else do:
          for each r-store
             where r-store.archive   = NO
               and r-store.firm-code = firm_code111 /* 111 */
               and (r-store.cli-code = 1 or r-store.cli-code = 2 or
                    r-store.cli-code = 8 or r-store.cli-code = 9 or
                    r-store.cli-code = 10 or r-store.cli-code = 11 or 
                    r-store.cli-code = 30 or r-store.cli-code = 32)
            no-lock:
            /* Две итерации, меняется параметр архивности */
            do ii = 1 to 2:
              iarc = (ii = 2).
              for each goods
                 where goods.archive   = iarc
                   and goods.gds-code  = r-goods.gds-code
                   and goods.cli-type  = 3
                   and goods.st-code   = r-store.cli-code
                   and goods.firm-code = firm_code111 /* 111 */
                  no-lock:
                   /* Получение остатков */
                  {_getremd.i
                    &card-buf     = goods
                    &date-field   = inv-date
                    &date-var     = "t-inv-date"
                    &cond-rem-var = condRemain}
                  totalRemain = totalRemain + condRemain.
              end.
            end.
          end.
        end.

        if totalRemain > 0 then do:
          find first TovarOst
               where TovarOst.gds-code = r-goods.gds-code
            no-lock no-error.
          if not available TovarOst then do:
            create TovarOst.
            assign
              TovarOst.gds-code = r-goods.gds-code
              TovarOst.fact-rem-upd = totalRemain.
          end.     
        end.
      end.  
    end.
  end.

  /* Поиск данных */
 /* output stream ggg to "isp-date.txt". */
  if KakoeRC = yes then 
    rc-type = 1. else
    rc-type = 2.
  /************************************************************/
  { ClassException.i }

  /************************************************************/
  run poisk_data. 

/*   output stream ggg close.
  if Opsys = "UNIX" then do:
    UNIX silent value("todos < ./isp-date.txt > ./temp").
    UNIX silent value("smbclient $DIRNS2000 '' -c 'put ./temp isp-date.txt' &> null").
  end.   */
  
  hide frame pro-fr no-pause.

  find first tmp1 no-lock no-error.
  if not available tmp1 then do:
    run _warn.p("1. Не найдено информации для отчета!").
    next cycle.
  end.

  /* Особенные остатки если выбрана только логистика */
  if (manyFirmsFormat = no and cli-code-flt = firm_code111) then do:
    /* Работа с итоговой таблицей */
    for each tmp1 exclusive-lock:
      totalRemain = 0.
      /* Поиск товаров на складах*/
      if FlagLogOst AND firm_code111 = 111 then do:
        run ost-logost.p (input tmp1.gds-code, 
                          input t-inv-date, 
                          input "fact-rem", 
                          input-output totalRemain).
      end.
      else do:
        for each r-store
           where r-store.archive   = NO
             and r-store.firm-code = firm_code111 /* 111 */
             and (r-store.cli-code = 1 or r-store.cli-code = 2 or
                  r-store.cli-code = 8 or r-store.cli-code = 9 or
                  r-store.cli-code = 10 or r-store.cli-code = 30 or r-store.cli-code = 32)
          no-lock:
          /* Две итерации, меняется параметр архивности */
          do ii = 1 to 2:
            iarc = (ii = 2).
            for each goods
               where goods.archive  = iarc
                 and goods.gds-code = tmp1.gds-code
                 and goods.cli-type  = 3
                 and goods.st-code   = r-store.cli-code
                 and goods.firm-code = firm_code111 /* 111 */
              no-lock:
               /* Получение остатков */
              {_getremd.i
                &card-buf     = goods
                &date-field   = inv-date
                &date-var     = "t-inv-date"
                &cond-rem-var = condRemain}
              totalRemain = totalRemain + condRemain.
            end.
          end.
        end.
      end.
      tmp1.cond-rem = totalRemain.
    end.
  end.

  /* Исключение товаров с нулевым или отрицательным условным остатком, если с учетом остатков РЦ */
  if true /* (countLogisticRemains = true) */ then do: /* С учетом остатков Семьи-Логистика, но похоже остатки нужны всегда */
    /* Работа с итоговой таблицей */
    for each tmp1 exclusive-lock:
      totalRemain = 0.
      /* Поиск товаров на складах*/
      if FlagLogOst AND firm_code111 = 111 then do:
        run ost-logost.p (input tmp1.gds-code, 
                          input t-inv-date, 
                          input "fact-rem", 
                          input-output totalRemain).

      end.
      else do:
        for each r-store
           where r-store.archive   = NO
             and r-store.firm-code = firm_code111 /* 111 */
             and (r-store.cli-code = 1 or r-store.cli-code = 2 or r-store.cli-code = 8 or
                 r-store.cli-code = 9  or r-store.cli-code = 10 or r-store.cli-code = 11 or 
                 r-store.cli-code = 20 or r-store.cli-code = 30 or r-store.cli-code = 32)
          no-lock:
          /* Две итерации, меняется параметр архивности */
          do ii = 1 to 2:
            iarc = (ii = 2).
            for each goods
               where goods.archive  = iarc
                 and goods.gds-code = tmp1.gds-code
                 and goods.cli-type  = 3
                 and goods.st-code   = r-store.cli-code
                 and goods.firm-code = firm_code111 /* 111 */
              no-lock:
               /* Получение остатков */
              {_getremd.i
                &card-buf     = goods
                &date-field   = inv-date
                &date-var     = "t-inv-date"
                &cond-rem-var = condRemain}
              totalRemain = totalRemain + condRemain.
            end.
          end.
        end.
      end.
      /* Обработка текущей записи в зависимости от остатков */
/* 07.07.17 Зебзеева просит убрать из отчета      
      if manyFirmsFormat then do: * Центр.Заявка *
        find first tmp-min-zap * Неснижаемый запас по Семье-Логистика *
             where tmp-min-zap.gds-code = tmp1.gds-code
          no-lock no-error.
        if available tmp-min-zap then do:
          totalRemain = totalRemain - tmp-min-zap.gds-ost.  
        end.
      end.
*/      
      if (totalRemain<=0) then do:
        if countLogisticRemains = true then delete tmp1.
      end.
      else do:
        tmp1.cond-rem = totalRemain.
      end.
    end.
  end.
  /* Проверка ПТЗ(tmp1.tovzap) по конкретной фирме в tmp-tov-zap.gds-ost  
  for each tmp1 exclusive-lock:
    find first tmp-tov-zap
      where tmp-tov-zap.firm-code = tmp1.firm-code
        and tmp-tov-zap.gds-code  = tmp1.gds-code
      use-index ind1 no-lock no-error.
    if available tmp-tov-zap then next.

    delete tmp1.

  end.
*/
  find first tmp1 no-lock no-error.
  if not available tmp1 then do:
    run _warn.p("2. Не найдено информации для отчета!").
    next cycle.
  end.

  run FindTOP1000.

  /* 611 =========================== */
  FlagErrorGraf = no.
  if FindGraf_ then do:  /* Проверяем только если выбрано По графикам - ДА */
    run CheckSchedule (OUTPUT FlagErrorGraf).
  end.  

  /* Вывод в файл */
  run vyvod_excel(no).

  firmcode = firmcodeBackup.
  /* Выход после формирования очтета нужен для завершения всех транзакций,
     иначе если не выходить, то в случае экстренного заверешния работы (ctrl+c), сгенерированные номера документов откатятся обратно,
     однако пользователь уже их выгрузил и работает с ними. */
  leave cycle.
end.

run endLogs.

hide frame footr no-pause.
hide frame ask-fr no-pause.

/* Поиск данных */
{ zayvin17.i } /* poisk_data searchByAlternativePeriod */

/* Поиск по АМ, вывод в файл */
{ zayvinam17.i } /* vyvod_excel searchByAlternativePeriod */

/* Поиск и вывод приоритетов */
{ zaylogPriorities.i } /* prioritiesToFile */

{ zayvin17graf.i }
/* Поиск и заполнение временной таблицы:
1) Всеми магазинами, если текущая фирма = 99
2) Только одним магазином в обратном случае 888 */

PROCEDURE fillChosenFirms: 
DEFINE INPUT PARAMETER currentFirm AS integer.
DEFINE INPUT PARAMETER TABLE FOR wf-firms.
DEFINE INPUT-OUTPUT PARAMETER TABLE FOR chosenFirms.
DEFINE OUTPUT PARAMETER manyFirmsFormat as logical.
DEFINE VARIABLE firmsCount AS INTEGER NO-UNDO.
define variable FlagGraf as logical no-undo.
define variable firmAlreadyCreated as logical no-undo.
define buffer sign-buf for sign.
define buffer r-store-buf for r-store.

  IF (currentFirm = 99) THEN DO:
    FindGraf_ = yes.
    run _ask.p (input-output FindGraf_, "По графику?" ). /* Вопрос. Будем проверять наличие графика поставки? */
    manyFirmsFormat = yes.
    /* Если выбрана 99 фирма, то по всем */
    FOR EACH r-firms 
       WHERE r-firms.archive = no and
             r-firms.code   <> 0  and
             r-firms.code   <> 99 and
             r-firms.code   <> 111 and
             r-firms.code   <> 600 and
             r-firms.code   <> 605 and
             r-firms.code    < 700
            NO-LOCK:
      
      /* Фирмы-исключенные из отчета (закрытые) */
      if r-firms.code = 552 OR 
         r-firms.code = 507 or 
         r-firms.code = 520 or 
         r-firms.code = 216 or 
         r-firms.code = 527 or 
         r-firms.code = 502 or 
         r-firms.code = 530 or
         r-firms.code = 509 or 
         r-firms.code = 559 or
         r-firms.code = 595 or  /* правильное вино */
         r-firms.code = 553 or  /* Зебзеева 11.09 */
         r-firms.code = 568 or  /* Зебзеева 11.09 */
         /* r-firms.code = 501 or */  /* Зебзеева 27.09 */
         r-firms.code = 580 or  /* Зебзеева 01.10 */
         r-firms.code = 575 or  /* Зебзеева 01.10 */
         r-firms.code = 540 or  /* Зебзеева 01.10 */
         r-firms.code = 506     /* Зебзеева 09.01.19 */
         then next.

      /* Проверка на закрытые фирмы */
      find first sign
           where sign.archive   = no
             and sign.file-code = 33
             and sign.sg-owner-net = r-firms.r-firms-net
             and sign.sg-owner-num = r-firms.r-firms-num
             and sign.sg-code      = 321
        no-lock no-error.     
      if available sign then next.

      /* Только фирмы, работающие с ТЗ */
      FIND FIRST csh-conf
           WHERE csh-conf.archive = no AND
                 csh-conf.firm-code = r-firms.code
        USE-INDEX firm-code NO-LOCK NO-ERROR.
      IF (AVAILABLE csh-conf) THEN DO:
        if FindGraf_ then do: /* проверим наличие графика */
          FlagGraf = no.
          run FindGraf (input r-firms.code, 
                        input-output FlagGraf).
        end.
        else FlagGraf = yes.
        firmAlreadyCreated = FindGraf_ = yes and r-firms.code = 546.
        if (FlagGraf) and (not firmAlreadyCreated) then do:
          CREATE chosenFirms.
          chosenFirms.firmRecId = RECID(r-firms).
        end.
      END.
    END.
  END.
  ELSE DO:
    firmsCount = 0.
    FOR EACH wf-firms no-lock:  
      firmsCount = firmsCount + 1.
    end.
    /* Если выбрано более одной фирмы */
    IF (firmsCount > 1) THEN DO:
      manyFirmsFormat = yes.
      FOR EACH wf-firms NO-LOCK:
        CREATE chosenFirms.
        chosenFirms.firmRecId = wf-firms.sel-rid.
      END.
    END.
    ELSE DO:
      /* Если выбрана одна фирма */
      manyFirmsFormat = no.
      FIND FIRST r-firms 
      WHERE r-firms.archive = no AND
            r-firms.code = currentFirm
      NO-LOCK NO-ERROR.
      IF (AVAILABLE r-firms) THEN DO:
        CREATE chosenFirms.
        chosenFirms.firmRecId = RECID(r-firms).
      END.

      manyFirmsFormat = yes.
    END.
  END.
END PROCEDURE.

PROCEDURE FindStore216.
  Flag216 = 0.
  run _menu40.p (?,?, "МАГАЗИНЫ ДИСКО",
                 'Декабристов 35',
                 output chs_).
END PROCEDURE.

PROCEDURE FindStore546.
define OUTPUT PARAMETER Flag546 as INTEGER.
  run _menu40.p (?,?, "СемьЯ у дома",
                 'Вагонная 27,' + 
                 'Холмогорская 4в',
                 output chs_).
  /* Вагонная 27, склад 1 */
  if (chs_ = 1) then do:
    flag546 = 1.
  end.
  else
  if (chs_ = 2) then do:
    Flag546 = 2.
  end.
  if chs_ <> ? then do:
    find first r-store
      where r-store.archive = no
        and r-store.firm-code = 546
        and r-store.cli-code  = Flag546
      no-lock no-error.
    if available r-store then do:
      find first sign /* ищем GLN */
           where sign.archive      = no
             and sign.file-code    = 075
             and sign.sg-owner-net = r-store.r-store-net
             and sign.sg-owner-num = r-store.r-store-num
             and sign.sg-code      = 250
        use-index list-ind no-lock no-error.
      if available sign then t_GLNfor546 = trim(sign.val).    
    end.  
  end.
/* message chs_ flag546. pause.   */
END PROCEDURE.

/* Являются ли выбранные классы взаимоисключащими */
FUNCTION classesIsMutuallyExclusive RETURNS LOGICAL ():
define variable mutuallyExclusiveClasses as logical no-undo init no.
define variable alkoClassFound as logical no-undo init no.
define variable nonAlkoClassFound as logical no-undo init no.
define variable chosenAllGoods as logical no-undo init no.

  for each w-f-class no-lock:
    find first class
         where recid(class) = w-f-class.sel-rid
      no-lock no-error.   
    if available class then do:
      if (class.class-code begins "28" or class.class-code begins "30") then do:
        alkoClassFound = yes.
      end. else do:
        nonAlkoClassFound = yes.
      end.
    end.
  end.
  if (alkoClassFound and nonAlkoClassFound) then do:
    mutuallyExclusiveClasses = yes.
  end.

  if (mutuallyExclusiveClasses = no) then do:
    for each work-file-r-goods no-lock:
      find first r-goods
          where recid(r-goods) = work-file-r-goods.sel-rid
      no-lock no-error.
      if (available r-goods) then do:
        find first link
             where link.archive    = no
               and link.file-name  = "r-goods"
               and link.object-net = r-goods.r-goods-net
               and link.object-num = r-goods.r-goods-num
               and link.type       = 19
        no-lock no-error.
        if (available link) then do:
          if (link.class-code begins "28" or link.class-code begins "30") then do:
            alkoClassFound = yes.
          end. else do:
            nonAlkoClassFound = yes.
          end.
        end.     
      end.
    end.
    if (alkoClassFound and nonAlkoClassFound) then do:
      mutuallyExclusiveClasses = yes.
    end.
  end.
  return mutuallyExclusiveClasses.
END FUNCTION.

PROCEDURE FindInv607.
  define VARIABLE t_year as integer no-undo.

  for each actions exclusive-lock:
    delete actions.
  end.

  for each isp-date exclusive-lock:
    delete isp-date.
  end.
  /* Стоп дата, или дата архивации(с какого числа есть данные) */
  gl_date = date(1,1,year(today)).
  find first r-net
       where r-net.archive = no
         and r-net.net = 1
    no-lock no-error.
  if available r-net then do:
    find first sign
         where sign.archive      = no
           and sign.file-code    = 36
           and sign.sg-owner-net = r-net.r-net-net
           and sign.sg-owner-num = r-net.r-net-num
           and sign.sg-code      = 242
      no-lock no-error.
    if available sign then do:
      t_year = int(trim(sign.val)) no-error.
      if NOT (t_year = ? OR t_year = 0) then do:
        gl_date = date(1,1,t_year) no-error.
        if gl_date = ? then gl_date = date(1,1,year(today)).
      end.
    end.
  end.

  for each invoice
     where invoice.firm-code    = 99
       and invoice.st-cli-type  = 3
       and invoice.st-code      = 99
       and invoice.storno       = no
       and invoice.cond-fact    = "фак"
       and invoice.GD-Type-Code = 607
    no-lock:

    if NOT (invoice.cli-type = 2) then next.
                                                                                      /* Зебзеева просит исключить Соц.цену из акций 31.01.17 */
    if invoice.cli-code = 1441 OR invoice.cli-code = 1784 OR invoice.cli-code = 1742 /* OR invoice.cli-code = 1287 */ then do:
      /* Дата окончания акции больше даты заявки, следовательно она еще действует и ее мы отбрасываем */
      if invoice.pay-date >= t-inv-date then next.

      for each gdsbody 
         where gdsbody.invoice-net = invoice.invoice-net
           and gdsbody.invoice-num = invoice.invoice-num
        no-lock:
        find first actions
             where actions.gds-code = gdsbody.gds-code
               and actions.beg-date = invoice.inv-date
               and actions.end-date = invoice.pay-date
          no-lock no-error.
        if NOT available actions then do:
          create actions.
          assign
            actions.gds-code = gdsbody.gds-code
            actions.beg-date = invoice.inv-date
            actions.end-date = invoice.pay-date
            actions.cli-code = 0
            actions.way-bill = ""  .
        end.
        
        if invoice.cli-code = 1742 then do:
          assign
            actions.way-bill = trim(invoice.way-bill)
            actions.cli-code = invoice.cli-code .
        end.
      end.
    end.
  end.     
end PROCEDURE.

PROCEDURE FindDateForSum.
  define input-output PARAMETER t_date     as date    no-undo.
  define input        PARAMETER t_gds_code as integer no-undo.
  define input PARAMETER t_gds_name as character no-undo.

  define VARIABLE j-date as date no-undo.
  define VARIABLE d-date as date no-undo.

  find first isp-date
       where isp-date.gds-code = t_gds_code
         and isp-date.gds-date = t_date /* Входящая дата */
    use-index ind1 no-lock no-error.
  if NOT available isp-date then do: /* Если не нашли, Создаем раскладку по дням */
    do j-date = usconf.m-p-from-date to (usconf.m-p-to-date - 1): /* Для каждого дня периода ищем подходящую дату */
    
      d-date = j-date.
      date-ckl:
      do while true:
        find first actions
          where actions.gds-code = t_gds_code
            and actions.beg-date <= d-date
            and actions.end-date >= d-date
          no-lock no-error.
        if available actions then do: /* товар в этот день в акции */
          /* if d-date <= gl_date then leave date-ckl. */
          d-date = d-date - 1.
          if d-date > gl_date then
            next date-ckl.
          else  d-date = gl_date.
        end. 
        else do:
        end.
        
        find first isp-date
          where isp-date.gds-code = t_gds_code
            and isp-date.real-date = d-date
          use-index ind2  no-lock no-error.
        if available isp-date then do: /* этот день уже занят */
          /* if d-date <= gl_date then leave date-ckl. */
          d-date = d-date - 1.
          if d-date > gl_date then
            next date-ckl.
          else  d-date = gl_date.          
        end.
        
        create isp-date.
        assign
          isp-date.gds-code  = t_gds_code
          isp-date.gds-date  = j-date
          isp-date.real-date = d-date  .

        leave date-ckl.
      end. /* do while true... */
    end. /* do j-date... */

    release isp-date.
    find first isp-date
      where isp-date.gds-code = t_gds_code
        and isp-date.gds-date = t_date /* Входящая дата */
      use-index ind1 no-lock no-error.
    if available isp-date then
      t_date = isp-date.real-date. else
      t_date = gl_date.

  end.
  else do:
    t_date = isp-date.real-date.
  end.

end PROCEDURE.

procedure FindGraf.
  define input PARAMETER t_firm_code as integer no-undo.
  define input-output PARAMETER FlagGraf as logical no-undo.
  define variable t_week-day as integer no-undo.
  define variable t-rc-code  as char no-undo.
  define variable FlagExistGraf as logical no-undo.

  FlagGraf = no.
  inv-ckl:
  for each tmp-cli no-lock:
    if tmp-cli.cli-code = 111 or tmp-cli.cli-code = 600 or tmp-cli.cli-code = 605 then do:

      if KakoeRC then t-rc-code = "30".  /* Код РЦ Бригадирской */
      else t-rc-code = "32".  /* Код РЦ Водопроводной */

      FlagExistGraf = no.
      invoiceSearch:
      for each invoice
         where invoice.firm-code    = t_firm_code
           and invoice.st-cli-type  = 3
           and invoice.st-code      = 90
           and invoice.storno       = no
           and invoice.cond-fact    = "фак"
           and invoice.gd-type-code = 611
           and invoice.cli-code     = tmp-cli.cli-code
           and invoice.inv-date    <= today
           and invoice.pay-num      = t-rc-code  /* важно, тут указывается код РЦ в новых графиках */
          no-lock
        break by invoice.way-bill
              by invoice.inv-date DESCENDING:
              /* by invoice.cont-date DESCENDING: кто это сделал ? При чем тут даа договора ? */

        /* Обработка только первого документа с этим классом */
        if (not first-of(invoice.way-bill)) then do:
          next invoiceSearch.
        end.

        /* Допускаются варианты - не указаны классы вообще, указан класс для алкоголя 210 */
        if invoice.way-bill <> "" then do:
          if NOT(invoice.way-bill begins "210") then next invoiceSearch.
        end. else next invoiceSearch.
          
 /* message "!График нашел." t_firm_code invoice.usr-inv-num invoice.inv-date invoice.way-bill. pause. */
        FlagExistGraf = yes.  /* факт того, что хотя бы один график существует на алкоголь */

        for each gdsbody
           where gdsbody.invoice-net = invoice.invoice-net 
             and gdsbody.invoice-num = invoice.invoice-num
          no-lock:

          t_week-day = 0.
          if gdsbody.gds-code = 002511166 then t_week-day = 2. else /* понедельник */
          if gdsbody.gds-code = 002511167 then t_week-day = 3. else /* вторник */
          if gdsbody.gds-code = 002511168 then t_week-day = 4. else /* среда */
          if gdsbody.gds-code = 002511169 then t_week-day = 5. else /* четверг */
          if gdsbody.gds-code = 002511170 then t_week-day = 6. else /* пятница */
          if gdsbody.gds-code = 002511171 then t_week-day = 7. else /* суббота */
          if gdsbody.gds-code = 002511172 then t_week-day = 1.      /* воскресенье */
          if t_week-day > 0 then do:
            /* if t_week-day = weekday(today) then do: */
            if t_week-day = weekday-i then do:
 /* message "!!График и день нашел." t_firm_code t_week-day weekday(today). pause. */
              FlagGraf = yes.
              leave inv-ckl.
            end.
          end.
        end.
      end.      
      /* В ситуации когда вообще не прогружены графики считаем что все хорошо, типа можно заказывать в любой день */
      if FlagExistGraf = no  then do:
/* message "!График НЕ нашел." t_firm_code. pause. */
        FlagGraf = yes.  
      end.  
    end.
    else do:
      /* Ветка поиска графика по старому */
      FlagExistGraf = no.

      invoiceSearch:
      for each invoice
         where invoice.firm-code    = t_firm_code
           and invoice.st-cli-type  = 3
           and invoice.st-code      = 90
           and invoice.storno       = no
           and invoice.cond-fact    = "фак"
           and invoice.gd-type-code = 611
           and invoice.cli-code     = tmp-cli.cli-code
           and invoice.inv-date    <= today
           and trim(invoice.pay-num) = ""   /* важно, тут указывается код РЦ в новых графиках */
          no-lock
        break by invoice.way-bill
              by invoice.inv-date DESCENDING:
              /* by invoice.cont-date DESCENDING: кто это сделал ? При чем тут даа договора ? */

        /* Обработка только первого документа с этим классом */
        if (not first-of(invoice.way-bill)) then do:
          next invoiceSearch.
        end.

        /* Допускаются варианты - не указаны классы вообще, указан класс для алкоголя 210 */
        if invoice.way-bill <> "" then do:
          if NOT(invoice.way-bill begins "210") then next invoiceSearch.
        end.  /* else next invoiceSearch. */

/* message "График нашел." t_firm_code invoice.usr-inv-num invoice.inv-date invoice.way-bill. pause. */
        FlagExistGraf = yes.  /* факт того, что хотя бы один график существует на алкоголь */

        for each gdsbody
           where gdsbody.invoice-net = invoice.invoice-net 
             and gdsbody.invoice-num = invoice.invoice-num
          no-lock:

          t_week-day = 0.
          if gdsbody.gds-code = 002511166 then t_week-day = 2. else /* понедельник */
          if gdsbody.gds-code = 002511167 then t_week-day = 3. else /* вторник */
          if gdsbody.gds-code = 002511168 then t_week-day = 4. else /* среда */
          if gdsbody.gds-code = 002511169 then t_week-day = 5. else /* четверг */
          if gdsbody.gds-code = 002511170 then t_week-day = 6. else /* пятница */
          if gdsbody.gds-code = 002511171 then t_week-day = 7. else /* суббота */
          if gdsbody.gds-code = 002511172 then t_week-day = 1.      /* воскресенье */
          if t_week-day > 0 then do:
            /* if t_week-day = weekday(today) then do: */
            if t_week-day = weekday-i then do:
              FlagGraf = yes.
              leave inv-ckl.
            end.
          end.
        end.
      end.      
      /* В ситуации когда вообще не прогружены графики считаем что все хорошо, типа можно заказывать в любой день */
      if FlagExistGraf = no  then do:
/* message "График НЕ нашел." t_firm_code. pause. */
        FlagGraf = yes.  
      end.  
    end.      
  end.
end procedure.

/* Получение года предыдущего периода */
FUNCTION getPreviousPeriodYear RETURNS INTEGER (): 
define variable previousPeriodYear as integer.
  find first base.r-net
       where base.r-net.archive = no
       and base.r-net.net = 1
  no-lock no-error.
  if (available base.r-net) then do:
    find first base.sign
       where base.sign.archive      = no
         and base.sign.file-code    = 36
         and base.sign.sg-owner-net = base.r-net.r-net-net
         and base.sign.sg-owner-num = base.r-net.r-net-num
         and base.sign.sg-code      = 242
    no-lock no-error.
    if available base.sign then do:
      previousPeriodYear = INT(base.sign.val) no-error.
    end.
  end.
  return previousPeriodYear.
END FUNCTION.

/* Связан ли товар с поставщиком */
function isGoodFromSupplier RETURNS LOGICAL(INPUT goodCode AS INTEGER, INPUT clientCode AS INTEGER):
define buffer r-store-buf for r-store.
define buffer goods-buf for goods.
  for each r-store-buf
     where r-store-buf.archive   = NO
       and r-store-buf.firm-code = 99 
       and r-store-buf.cli-code  = 99
  use-index clifirm-ind no-lock:
    for each goods-buf
       where goods-buf.archive   = no
         and goods-buf.firm-code = 111 
         and goods-buf.cli-type  = 3
         and goods-buf.st-code   = r-store-buf.cli-code
         and goods-buf.gds-code  = goodCode
    use-index gds-code-ind-T no-lock:
      if (goods-buf.cli-code = clientCode) then do:
        return yes.
      end.
    end.
  end.
  return no.
end function.

/* Поиск товаров по поставщику */
PROCEDURE searchGoodsByClient:
DEFINE INPUT PARAMETER firmCodeT AS INTEGER.
DEFINE INPUT PARAMETER clientCode AS INTEGER.
DEFINE OUTPUT PARAMETER TABLE FOR clientsGoods.
define buffer goods-buf for goods.
define buffer r-goods-buf for r-goods.
/* message "PROCEDURE searchGoodsByClient:". pause. */
/* Выборка товаров на Семье-Логистике нужен если поставщик не сама Логистика */
if clientCode <> 111 and clientCode <> 600 and clientCode <> 605 then do:

  for each goods-buf
     where goods-buf.archive   = no
       and goods-buf.firm-code = firmCodeT
       and goods-buf.cli-type  = 3
       and goods-buf.st-code   = 99
       and goods-buf.cli-code  = clientCode
    no-lock:

    find first r-goods-buf
         where r-goods-buf.gds-code = goods-buf.gds-code
           and r-goods-buf.archive = no
      use-index goods-code-ind no-lock no-error.
    if available r-goods-buf then do:

      find first clientsGoods
           where clientsGoods.goodCode   = r-goods-buf.gds-code
             and clientsGoods.clientCode = clientCode
        no-lock no-error.
      if not available clientsGoods then do:
/* if r-goods-buf.locode = "593574" then do:
  message "clientsGoods". pause.
end. */
        create clientsGoods.
        assign
          clientsGoods.goodCode     = r-goods-buf.gds-code
          clientsGoods.clientCode   = clientCode.
      end.
    end.
  end.
end.
END PROCEDURE.

/* Поиск наличия алкогольной лицензии на фирме */
procedure AlkoLicen:
define input parameter t-cli-code as integer no-undo.
define output parameter FlagAlko  as logical no-undo.

define variable t-date-beg  as date no-undo.
define variable t-date-end  as date no-undo.
define variable t-day       as integer no-undo.
define variable t-month     as integer no-undo.
define variable t-year      as integer no-undo.

FlagAlko = yes.

/*  Зебзеева 19.04.18 из-за проблем c лицензией Новой Семьи просит отключить проверку
find first clients
     where clients.archive  = no
       and clients.cli-code = t-cli-code
  no-lock no-error.
if available clients then do:
  find first sign
       where sign.archive      = no
         and sign.file-code    = 7
         and sign.sg-owner-net = clients.clients-net
         and sign.sg-owner-num = clients.clients-num
         and sign.sg-code      = 228
    use-index list-ind no-lock no-error.
  if available sign then do:
    t-day =   int(substring(entry(3,sign.val,";"),1,2)) no-error.
    t-month = int(substring(entry(3,sign.val,";"),4,2)) no-error.
    t-year =  int(substring(entry(3,sign.val,";"),7,4)) no-error.

    t-date-beg = date(t-month,t-day,t-year) no-error.

    t-day =   int(substring(entry(4,sign.val,";"),1,2)) no-error.
    t-month = int(substring(entry(4,sign.val,";"),4,2)) no-error.
    t-year =  int(substring(entry(4,sign.val,";"),7,4)) no-error.

    t-date-end = date(t-month,t-day,t-year) no-error.

    if t-date-beg = ? or t-date-end = ? then do:
      FlagAlko = no.
    end.  
    else do:
      if Not(t-inv-date >= t-date-beg and t-inv-date <= t-date-end) then do:
        FlagAlko = no.
      end.
    end.
  end.
  else do:
    FlagAlko = no.
  end.  
end.        
*/
end procedure.

procedure FilterGoodsRC. 
  define input  PARAMETER tmp-gds-code as integer no-undo.
  define input  PARAMETER rc-type      as integer no-undo.
  define output PARAMETER tmp-OK       as logical no-undo.
  tmp-OK = no.
  /* код РЦ товара */
  run fstorerc.p (input tmp-gds-code, input today, output t-codeRC, 1).  
  if rc-type = 1 AND t-codeRC = 30 then tmp-OK = yes. else
  if rc-type = 2 AND t-codeRC = 32 then tmp-OK = yes.
end procedure.

procedure SearchForAssortment. /* поиск ассортимента поставщика РЦ */
define variable FirstOf as logical no-undo.
  FirstOf = yes.
  for each work-file-r-goods exclusive-lock:
    delete work-file-r-goods.
  end.  

  for each goods 
     where goods.archive   = no
       and goods.firm-code = cli-code-flt
       and goods.cli-type  = 3
       and goods.st-code   = 99
       and goods.cli-code  = cli-code-psv
    no-lock:
    
    find first r-goods
         where r-goods.archive  = no
           and r-goods.gds-code = goods.gds-code
      no-lock no-error.
    if NOT available r-goods then next.
/* 
    if FirstOf then do:
      FirstOf = no.
      for each work-file-r-goods exclusive-lock:
        delete work-file-r-goods.
      end.
    end.
 */
    find first work-file-r-goods
         where work-file-r-goods.sel-rid = recid(r-goods)
      no-lock no-error.
    if available work-file-r-goods then next.
    create work-file-r-goods.
    assign work-file-r-goods.sel-rid = recid(r-goods).

  end.
end procedure.
