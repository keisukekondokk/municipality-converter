*******************************************************************************
** (C) Keisuke Kondo
** 
** Kondo, Keisuke (2019) "Municipality-level panel data and municipal mergers 
** in Japan," RIETI Technical Paper 19-T-001
*******************************************************************************

**===============================================
** 経済産業省「工業統計調査」の各年データの再集計
**===============================================
forvalues i = 2002(1)2012 {
	
	** 経済産業省「工業統計調査」市区町村編のデータ
	use "data_manu/DTA_meti_manu`i'.dta", clear

	** 製造業全体のみを選択
	keep if id_sec2d == 0

	** 市区町村コードでソート
	sort id_muni

	** コンバータとの接続キーを作成する
	gen match_id_muni = id_muni

	** 接続キーを用いてコンバータ内の2015年時点の市区町村コードと市区町村名を追加
	merge 1:1 match_id_muni using "Municipality_Converter_Kondo_RIETI_TP_19-T-001_JP.dta", keepusing(id_muni2015 name_muni2015)

	** 原データ側にしかなかった不要な情報を削除（接続漏れがないか念のため確認）
	drop if _merge == 1

	** 2015年時点の市区町村コードによって再集計する
	by id_muni2015, sort: egen totalsales = total(sales), missing
	replace totalsales = totalsales / 100
	replace year = `i'
	
	** 重複を削除する
	duplicates drop id_muni2015, force
	
	** データの整形
	sort id_muni2015
	keep year id_muni2015 name_muni2015 totalsales

	** 2015 年基準で再集計した過去データの保存
	save "data_manu/DTA_meti_manu`i'_base2015.dta", replace
}


**===============================================
** 内閣府「選択する未来」委員会における市区町村データと統合
**===============================================
forvalues i = 2002(1)2012 {
	** 内閣府　市区町村データ
	use "data_manu/DTA_meti_manu`i'_base2015.dta", replace

	** 接続キーの作成
	gen id_muni = id_muni2015

	** 接続キーを用いてコンバータ内の2015年時点の市区町村コードと市区町村名を追加
	merge 1:1 id_muni using "data_manu/DTA_cao_manu.dta", keepusing(manu`i')
	drop _merge

	** データの整形
	rename manu`i' manu
	drop id_muni
	
	** データを保存
	save "data_manu/DTA_meti_manu`i'_base2015_with_cao.dta", replace
}


**===============================================
** コンバータの正確性を検証
**===============================================

** メモリ上のデータを削除
clear

** 5年毎のループ処理で，long型のパネルデータを構築
forvalues i = 2002(1)2012 {
	append using "data_manu/DTA_meti_manu`i'_base2015_with_cao.dta"
}

**　パネルデータを保存
save "data_manu/DTA_panel_meti_manu_base2015_with_cao.dta", replace

** 市区町村コンバータによる集計結果と内閣府の市区町村パネルデータの差を比較
gen diff = round(totalsales) - manu
replace diff = totalsales - manu if year == 2012

** 誤差が生じた市区町村の一覧
browse if diff > 1 | diff < -1 
