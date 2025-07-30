/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	НАВИГАТОР ТАБЛИЦЫ

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
class NavTable {
	//
	//	Свойства объекта
	//
	prev;		// Кнопка "Следующий"
	next;		// Кнопка "Предыдущий"
	table;		// Таблица
	rows = [];	// массив строк таблицы
	offset;		// смещение строки в таблице
	limit;		// количество видимых строк таблицы
	//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	//
	//	Конструктор https://learn.javascript.ru/class
	//
	constructor( param ) {
		//
		//	кнопки навигации
		this.prev = param["navbar"].querySelector("[name='prev']");
		this.next = param["navbar"].querySelector("[name='next']");
		//
		//	Таблица
		this.table = param["table"];
		//
		//	смещение строки в таблице
		this.offset = param["navbar"].querySelector("input[type='hidden']");
		//	проверка значения
		if ( isNaN(parseInt(this.offset.value)) )
		{
			this.offset.value = 0;
		}
		//
		//	количество видимых строк таблицы
		this.limit = param["limit"] || 10;
		//
		//	количество колонок в строке
		let cols = this.table.rows[0].cells.length;
		//
		//	цикл по всем строкам таблицы
		for (let i = 0; i < this.table.rows.length; i++)
		{
			//
			//	добавить в массив
			if ( this.table.rows[i].cells.length == cols )
			{
				this.rows.push({
					index:		i,
					rowspan:	this.table.rows[i].cells[0].rowSpan,
				});
			}
		}
		//	выход из диапазона?
		if ( this.offset.value >= this.rows.length )
		{
			this.offset.value = 0;
		}
//		console.dir(this.rows);
		//####################################################################
		//
		//	СЛУШАТЕЛИ событий
		//
		this.prev.addEventListener("click", (event) => {
			this.ShiftVisibiledRows(-1);
		});
		this.next.addEventListener("click", (event) => {
			this.ShiftVisibiledRows(+1);
		});
		//
		//	показать строки таблицы
		this.ShiftVisibiledRows(0);
	}
	//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	//
	//	Изменить стиль группы строк (записи таблицы)
	//
	setStyleDisplayEntry(index = NaN, value = "none" ) {
		//
		//	параметры записи (группы строк таблицы)
		let entry = this.rows[index];
		//
		//	цикл по всем строкам таблицы из записи
		for (let i = 0; i < entry.rowspan; i++)
		{
			//
			//	изменить стиль строки таблицы
			this.table.rows[i + entry.index].style.display = value;
		}
	}
	//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	//
	//	Показать строки таблицы
	//
	ShiftVisibiledRows( sign = 1 ) {
		//
		//	строки таблицы
		let rows = this.rows;
		//
		//	увеличение и корректировка смещения
		this.offset.value = parseInt(this.offset.value) + sign*this.limit;
		if (parseInt(this.offset.value) < 0) { this.offset.value = 0 };
		//
		//	диапазон видимых строк
		let start = parseInt(this.offset.value);
		let end = start + this.limit;
		if (end >= rows.length) { end = rows.length };
		//
		//	цикл по строкам таблицы
		for (let i = 0; i < rows.length; i++)
		{
			if (i >= start && i < end)	// показать строки
			{
				this.setStyleDisplayEntry(i, "");
			}
			else						// скрыть строки
			{
				this.setStyleDisplayEntry(i, "none");
			}
		}
		//
		//	выход из диапазона?
		this.prev.disabled = (parseInt(this.offset.value) == 0);
		this.next.disabled = (end >= rows.length);
	}
}
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::