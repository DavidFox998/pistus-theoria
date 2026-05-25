import { Router, type IRouter } from "express";
import healthRouter from "./health";
import storageRouter from "./storage";
import certificatesRouter from "./certificates";
import leanRouter from "./lean";
import morningstarRouter from "./morningstar";

const router: IRouter = Router();

router.use(healthRouter);
router.use(storageRouter);
router.use(certificatesRouter);
router.use(leanRouter);
router.use(morningstarRouter);

export default router;
