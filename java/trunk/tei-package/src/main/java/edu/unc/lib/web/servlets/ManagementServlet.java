package edu.unc.lib.web.servlets;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import edu.unc.lib.web.listeners.UploadContextListener;

public class ManagementServlet extends DispatcherServlet {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		req.setAttribute("config", getApplicationConfig());
		handleDispatch(req,resp);
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		String assetLocations = req.getParameter("assetLocations");
		if ( assetLocations != null ) {
			String oldValue = getApplicationConfig().getAssetLocationString();
			getApplicationConfig().setVariable(UploadContextListener.XPROC_LOCATIONS, assetLocations);
			req.setAttribute("changedAttribute", String.format("old: '%s', new '%s'", oldValue, assetLocations));
		}
		req.setAttribute("config", getApplicationConfig());
		handleDispatch(req,resp);
	}

	@Override
	public String getDefaultDispatchURL() {
		return "/config.jsp";
	}
	
	
	
	
	
	

}
