--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cbs; Type: TABLE; Schema: public; Owner: lite; Tablespace: 
--

CREATE TABLE cbs (
    txid text NOT NULL,
    utime integer NOT NULL,
    input text NOT NULL,
    amount real NOT NULL,
    conf integer DEFAULT 0 NOT NULL,
    state integer NOT NULL
);


ALTER TABLE public.cbs OWNER TO lite;

--
-- Name: monitor; Type: TABLE; Schema: public; Owner: lite; Tablespace: 
--

CREATE TABLE monitor (
    input text NOT NULL,
    dest text,
    cburl text,
    fee real DEFAULT 0 NOT NULL,
    donate real DEFAULT 0 NOT NULL,
    min_forward real DEFAULT 0 NOT NULL,
    verify_ssl boolean DEFAULT true NOT NULL
);


ALTER TABLE public.monitor OWNER TO lite;

--
-- Name: tx; Type: TABLE; Schema: public; Owner: lite; Tablespace: 
--

CREATE TABLE tx (
    id text NOT NULL,
    timer integer NOT NULL,
    bhash text NOT NULL,
    addr text NOT NULL,
    amount real NOT NULL,
    conf integer,
    state integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.tx OWNER TO lite;

--
-- Name: cbs_pkey; Type: CONSTRAINT; Schema: public; Owner: lite; Tablespace: 
--

ALTER TABLE ONLY cbs
    ADD CONSTRAINT cbs_pkey PRIMARY KEY (txid, input);


--
-- Name: monitor_pkey; Type: CONSTRAINT; Schema: public; Owner: lite; Tablespace: 
--

ALTER TABLE ONLY monitor
    ADD CONSTRAINT monitor_pkey PRIMARY KEY (input);


--
-- Name: tx_pkey; Type: CONSTRAINT; Schema: public; Owner: lite; Tablespace: 
--

ALTER TABLE ONLY tx
    ADD CONSTRAINT tx_pkey PRIMARY KEY (id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

