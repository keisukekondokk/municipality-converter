*******************************************************************************
** (C) Keisuke Kondo
** 
** Kondo, Keisuke (2019) "Municipality-level panel data and municipal mergers 
** in Japan," RIETI Technical Paper 19-T-001
*******************************************************************************

**===============================================
** 総務省「国勢調査」の各年データの再集計
**===============================================
forvalues i = 1980(5)2010 {

	** 国勢調査の市区町村データ
	use "data_pop/DTA_estat_pop`i'.dta", clear

	** 年次を追加
	gen year = `i'

	** 市区町村コードでソート
	sort id_muni

	** コンバータとの接続キーを作成する
	gen merge_id_muni = id_muni

	** 接続キーを用いてコンバータ内の2015年時点の市区町村コードと市区町村名を追加
	merge 1:1 merge_id_muni using "municipality_converter_jp.dta", keepusing(id_muni2015 name_muni_jp2015)

	** 原データ側にしかなかった不要な情報を削除（接続漏れがないか念のため確認）
	drop if _merge == 1
	
	** コンバータ側にしかなかった不要な情報を削除（接続漏れがないか念のため確認）
	drop if id_muni2015 == .

	** 2015年時点の市区町村コードによって再集計する
	by id_muni2015, sort: egen totalpop = total(pop), missing
	replace year = `i'
	
	** 重複を削除する
	duplicates drop id_muni2015, force
	
	** データの整形
	sort id_muni2015
	keep year id_muni2015 name_muni_jp2015 totalpop

	** 2015 年基準で再集計した過去データの保存
	save "data_pop/DTA_estat_pop`i'_base2015.dta", replace
}


**===============================================
** 内閣府「選択する未来」委員会における市区町村データと統合
**===============================================
forvalues i = 1980(5)2010 {

	** 内閣府　市区町村データ
	use "data_pop/DTA_estat_pop`i'_base2015.dta", replace

	** 接続キーの作成
	gen id_muni = id_muni2015

	** 接続キーを用いてコンバータ内の2015年時点の市区町村コードと市区町村名を追加
	merge 1:1 id_muni using "data_pop/DTA_cao_pop.dta", keepusing(pop`i')
	drop _merge

	** データの整形
	rename pop`i' pop
	drop id_muni
	
	** データを保存
	save "data_pop/DTA_estat_pop`i'_base2015_with_cao.dta", replace
}


**===============================================
** コンバータの正確性を検証
**===============================================

** メモリ上のデータを削除
clear

** 5年毎のループ処理で，long型のパネルデータを構築
forvalues i = 1980(5)2010 {
	append using "data_pop/DTA_estat_pop`i'_base2015_with_cao.dta"
}

**　パネルデータを保存
save "data_pop/DTA_panel_estat_pop_base2015_with_cao.dta", replace

** 市区町村コンバータによる集計結果と内閣府の市区町村パネルデータの差を比較
gen diff = round(totalpop) - pop

** 誤差が生じた市区町村の一覧
browse if diff > 1 | diff < -1 
