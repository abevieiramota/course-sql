-- Drop table

-- DROP TABLE public.bens

CREATE TABLE public.bens (
	sq_candidato int8 NULL,
	nr_ordem_candidato int8 NULL,
	cd_tipo_bem_candidato int8 NULL,
	ds_tipo_bem_candidato varchar(112) NULL,
	ds_bem_candidato varchar(300) NULL,
	vr_bem_candidato numeric(13,2) NULL,
	CONSTRAINT sq_candidato_fk FOREIGN KEY (sq_candidato) REFERENCES candidato(sq_candidato)
)
WITH (
	OIDS=FALSE
) ;
CREATE INDEX bens_candidato_idx ON bens USING btree (sq_candidato) ;
