--Ej 1 de SQL


--1)
SELECT clie_codigo Codigo, clie_razon_social Razon_Social
		from Cliente where clie_limite_credito >= 1000
		order by Codigo


--2)
select * from Producto

select prod_codigo Codigo, prod_detalle Detalle, SUM(ITF.item_cantidad) 
		from Producto P JOIN Item_Factura ITF ON P.prod_codigo = ITF.item_producto
		JOIN Factura F ON F.fact_tipo = ITF.item_tipo and F.fact_sucursal = ITF.item_sucursal
		and F.fact_numero = ITF.item_numero and YEAR(F.fact_fecha) = '2012'
		GROUP BY prod_codigo, prod_detalle
		ORDER BY SUM(ITF.item_cantidad) DESC

--3)
select  prod_codigo, prod_detalle, SUM(s.stoc_cantidad) AS Stock
from Producto P JOIN Stock S ON p.prod_codigo = s.stoc_producto
group by prod_codigo, prod_detalle
order by prod_detalle asc


--4) --DUDAS CON ESTE, recursividad en la composicion?
select prod_codigo, prod_detalle, COUNT(Co.comp_componente), COUNT(ST.stoc_deposito) AS Deposito
from Producto P LEFT JOIN Composicion Co ON prod_codigo = Co.comp_producto JOIN STOCK ST
	on st.stoc_producto = P.prod_codigo
	group by prod_codigo, prod_detalle
	having AVG(st.stoc_cantidad)>100


--5)							
SELECT prod_codigo, prod_detalle,   SUM(item_cantidad) AS Egresos 
FROM Producto P JOIN  Item_Factura ITF on P.prod_codigo = ITF.item_producto JOIN Factura F on
	F.fact_numero = ITF.item_numero and YEAR(F.fact_fecha) = 2012		
group by prod_codigo, prod_detalle
having SUM(item_cantidad) > (SELECT SUM(item_cantidad) FROM Item_Factura, Factura where
								item_producto = P.prod_codigo and
								item_numero = fact_numero and item_tipo = fact_tipo and
								fact_sucursal = item_sucursal and YEAR(fact_fecha) = 2011)
								
								
--6)
SELECT rubr_id, rubr_detalle, COUNT(P.prod_codigo) AS 'Productos del rubro', SUM(S.stoc_cantidad) AS Stock
FROM Rubro R JOIN Producto P ON R.rubr_id = P.prod_rubro JOIN STOCK S ON S.stoc_producto = P.prod_codigo
group by rubr_id, rubr_detalle
having SUM(S.stoc_cantidad) > (SELECT SUM(stoc_cantidad) FROM STOCK JOIN Producto
							 on prod_codigo = '00000000' and
							 prod_codigo = stoc_producto
								JOIN DEPOSITO on depo_codigo = '00' and depo_codigo = stoc_deposito)
								
--7)
SELECT  P.prod_codigo, P.prod_detalle, MIN(ITF.item_precio) AS Minimo, MAX(ITF.item_precio) AS Maximo,
		((MAX(ITF.item_precio) - MIN(ITF.item_precio))*100 / MIN(ITF.item_precio) ) AS 'Porcentaje de dif'
  From Producto  P JOIN Item_Factura ITF on P.prod_codigo = ITF.item_producto
  
  group by P.prod_codigo, P.prod_detalle
  having EXISTS(SELECT 1 FROM STOCK where stoc_producto = P.prod_codigo and stoc_cantidad >0)
  
 	 
					 
				
				
