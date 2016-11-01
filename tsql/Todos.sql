CREATE FUNCTION Ej1 (@articulo char(8), @deposito char(2))

RETURNS VARCHAR(255)
AS

BEGIN
DECLARE @Estado VARCHAR(255)
DECLARE @Stoc_Actual DECIMAL(12,2)
DECLARE @Stoc_limite DECIMAL(12,2)

SELECT @Stoc_Actual = ST.stoc_cantidad, @Stoc_limite = ST.stoc_stock_maximo
FROM Producto P JOIN STOCK ST ON stoc_deposito = @deposito AND stoc_producto = @articulo
			
 IF @Stoc_Actual < @Stoc_limite

 SET @Estado = 'Ocupacion del deposito ' + convert(varchar(20),(@Stoc_Actual * 100 / @Stoc_limite)) + '%'

 ELSE

	SET @Estado = 'Deposito lleno'

RETURN @Estado

END




-- Devuelve los articulos y depositos cuyo stoc no alcanzo al maximo
select  prod_codigo AS Articulo, depo_codigo  As Deposito, prod_detalle Detalle 
FROM Producto JOIN STOCK ON stoc_producto = prod_codigo JOIN DEPOSITO ON depo_codigo = stoc_deposito 
where stoc_stock_maximo > stoc_cantidad



--Corrige la tabla de empleados para que haya un solo gerente general segun los criterios del enunciado (maximo sueldo, y si hay iguales, por antiguedad)

CREATE PROCEDURE Ej3
@empleados_sin_jefe integer OUTPUT


AS
BEGIN


SELECT @empleados_sin_jefe = COUNT(*) FROM Empleado WHERE empl_jefe is null

if @empleados_sin_jefe > 1 
	BEGIN
	DECLARE @idGerenteGeneral numeric(6)
	DECLARE @resultado integer
		
	SELECT @resultado = COUNT(*) FROM Empleado where empl_salario = (SELECT MAX(empl_salario) FROM Empleado) 
		and empl_jefe is null
		
	if(@resultado > 1)
	begin
	print 'resultado mayorr a 1 '	
	SELECT @idGerenteGeneral = empl_codigo FROM Empleado where empl_salario = (SELECT MAX(empl_salario) FROM Empleado) 
		and empl_jefe is null and DATEDIFF(day,empl_ingreso,GETDATE()) = (SELECT MAX(DATEDIFF(day,empl_ingreso, GETDATE())) FROM Empleado)
	end
	else 
	SELECT @idGerenteGeneral = empl_codigo FROM Empleado where empl_salario = (SELECT MAX(empl_salario) FROM Empleado) 
		and empl_jefe is null	


	UPDATE  EMPLEADO SET empl_jefe = @idGerenteGeneral where empl_codigo != @idGerenteGeneral and empl_jefe is null
	
	END
	




END



-----Funcion que devuelve el salario maximo de empleado
CREATE FUNCTION fx_get_max_salario()
returns decimal(12,2)
AS

BEGIN
DECLARE @max decimal(12,2)
SELECT @max = MAX(empl_salario) FROM Empleado
return @max
END

-----Stored procedure del ejercicio 3
CREATE PROCEDURE Ej3_2
@sin_jefes integer output

AS

BEGIN

SELECT @sin_jefes = COUNT(*) 
FROM Empleado where empl_jefe IS NULL

if @sin_jefes > 1
	--arreglo la base de datos
	BEGIN
	DECLARE @id_gerente_gral numeric(6)
	DECLARE @cant_jefes_con_mayor_salario integer
	SELECT @cant_jefes_con_mayor_salario = count(*) from Empleado 
							where empl_salario = (select dbo.fx_get_max_salario()) AND empl_jefe IS NULL
	if @cant_jefes_con_mayor_salario > 1
		BEGIN
		SELECT @id_gerente_gral = empl_codigo From Empleado where empl_salario = (select dbo.fx_get_max_salario())
						 AND empl_jefe IS NULL 
						 AND DATEDIFF(DAY,empl_ingreso, GETDATE()) = (SELECT MAX(DATEDIFF(DAY,empl_ingreso, GETDATE())) 
																	FROM Empleado where empl_jefe IS NULL)
		END
	else
		BEGIN 
		SELECT @id_gerente_gral =  empl_codigo FROM Empleado where empl_salario = (select dbo.fx_get_max_salario()) and empl_jefe IS NULL
		
		UPDATE Empleado SET empl_jefe = @id_gerente_gral where empl_codigo != @id_gerente_gral AND empl_jefe IS NULL
		END
	END



END

--invocacion del SP
DECLARE @output decimal(12,2)
exec Ej3_2 @sin_jefes  = @output




-----------EJERCICIO 4
-- Setea a todos los empleados su comision que es la suma de los totales de todas las facturas del 2012 (en el enunciado decia del año anterior)
CREATE PROCEDURE SETCOMISION

@idEmpleadoConMasVentas numeric(6) OUTPUT



AS
BEGIN
DECLARE @idEmpleado numeric(6)
DECLARE @totalVentas integer



DECLARE CursorComision CURSOR
FOR
SELECT E.empl_codigo, SUM(F.fact_total) As Total_Vendido FROM Empleado E JOIN FACTURA F
 ON E.empl_codigo = F.fact_vendedor AND YEAR(F.fact_fecha) = '2012'
group by E.empl_codigo, E.empl_apellido, E.empl_nombre
order by Total_Vendido DESC

OPEN CursorComision
FETCH CursorComision INTO @idEmpleado, @totalVentas
while(@@FETCH_STATUS = 0)
BEGIN

UPDATE EMPLEADO SET empl_comision = @totalVentas where empl_codigo = @idEmpleado

FETCH CursorComision INTO @idEmpleado, @totalVentas
END
CLOSE CursorComision
DEALLOCATE CursorComision

SELECT @idEmpleadoConMasVentas = E.empl_codigo FROM Empleado E JOIN FACTURA F
 ON E.empl_codigo = F.fact_vendedor AND YEAR(F.fact_fecha) = '2012'
  AND E.empl_comision = (SELECT MAX(empl_comision) FROM Empleado)
group by E.empl_codigo


END






ALTER PROCEDURE Ej4_2
@id_mayor_vendedor numeric(6) output

AS

BEGIN
DECLARE @sumatoria integer
DECLARE @id_empleado numeric(6)
DECLARE @mayor_comision integer

DECLARE CursorComision CURSOR

FOR SELECT E.empl_codigo, SUM(F.fact_total) As Total FROM Empleado E JOIN Factura F ON E.empl_codigo = F.fact_vendedor
where YEAR(fact_fecha) = '2012'
group by E.empl_codigo


OPEN CursorComision

FETCH CursorComision INTO @id_empleado, @sumatoria
SET @mayor_comision = @sumatoria
SET @id_mayor_vendedor = @id_empleado
while(@@FETCH_STATUS = 0)
	BEGIN
	if @sumatoria > @mayor_comision
		BEGIN
		SET @mayor_comision = @sumatoria
		SET @id_mayor_vendedor = @id_empleado
		END

	UPDATE Empleado SET empl_comision = @sumatoria where empl_codigo =  @id_empleado
	FETCH CursorComision INTO @id_empleado, @sumatoria
	END
CLOSE CursorComision
DEALLOCATE CursorComision




END


DECLARE @id_vendedor numeric(6)
exec dbo.SETCOMISION @idEmpleadoConMasVentas = @id_vendedor
GO


----------------Ejercicio 11------------------------
CREATE FUNCTION Ej11 (@id_empleado numeric(6))
returns integer
AS
BEGIN
DECLARE @contador integer

	SET @contador = (SELECT COUNT(*) FROM Empleado where empl_jefe = @id_empleado)
	if @contador > 0
	BEGIN
	SET @contador = @contador + (select sum(dbo.Ej11(empl_codigo))  FROM Empleado where empl_jefe = @id_empleado)
	
	END

	return @contador
END

select dbo.Ej11 (1)
GO
---------------------Ejercicio 12-------------

CREATE TRIGGER cantidad_empleados ON Empleado
AFTER INSERT, UPDATE
AS
BEGIN

IF EXISTS (SELECT * FROM Empleado where (select dbo.Ej11(empl_codigo)) > 50)
BEGIN 
RAISERROR('Un jefe no puede tener mas  de 50 empleados', 16,1)
ROLLBACK TRANSACTION
END
	

END
GO

select * from Empleado
GO

----------------------Ejercicio 13------------------
CREATE TRIGGER Ej13 ON Composicion
AFTER INSERT,UPDATE

AS

BEGIN
IF EXISTS( SELECT  * FROM Composicion C where comp_producto = comp_componente)
BEGIN
RAISERROR('Ningun producto puede estar compuesto por si mismo', 16,1)
ROLLBACK TRANSACTION
END
END

--codigo de prueba
BEGIN
	DECLARE @A char(8), @B char(8), @C char(8)
	SELECT TOP 1 @A=prod_codigo FROM Producto
	SELECT TOP 1 @B=prod_codigo FROM Producto WHERE prod_codigo not in (@A)
	SELECT TOP 1 @C=prod_codigo FROM Producto WHERE prod_codigo not in (@A, @B)

	-- bucle de 1 nodo (reflexividad) SALTA EL TRIGGER
	INSERT INTO Composicion values (1,@A,@A)

END
GO

----------------------Ejercicio 14--------------------
ALTER TRIGGER Ej14 ON Empleado
AFTER INSERT,UPDATE, DELETE
AS
BEGIN

IF EXISTS (
SELECT Jefe.empl_codigo, Jefe.empl_salario
FROM Empleado Jefe JOIN Empleado  E ON E.empl_jefe = Jefe.empl_codigo
where (Jefe.empl_salario * 0.2 ) > (select dbo.fx_get_suma_salario_subordinados(Jefe.empl_codigo))
 AND ((select dbo.Ej11(E.empl_codigo)) > 0)		
 
 )
BEGIN
RAISERROR('No puede haber un jefe con un salario mayor al 20% de la suma de los subordinados',16,1)
ROLLBACK TRANSACTION
END

END
GO

ALTER FUNCTION fx_get_suma_salario_subordinados(@id_jefe numeric(6))
returns int
AS
BEGIN
DECLARE @sumatoria int
DECLARE @subordinados_directos int

SET @sumatoria = 0
SET @subordinados_directos = (SELECT COUNT(*) FROM Empleado where empl_jefe = @id_jefe)
	if @subordinados_directos > 0
	BEGIN
	
	SET  @sumatoria =  (SELECT SUM(empl_salario) FROM Empleado  where empl_jefe = @id_jefe AND empl_salario IS NOT NULL)
	SET @sumatoria = @sumatoria + (SELECT SUM(dbo.fx_get_suma_salario_subordinados(empl_codigo)) 
								FROM Empleado  where empl_jefe = @id_jefe)
	END
 
return @sumatoria
END


select dbo.fx_get_suma_salario_subordinados(1)  


select * from Empleado
